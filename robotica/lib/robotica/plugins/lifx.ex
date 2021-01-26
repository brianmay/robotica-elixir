defmodule Robotica.Plugins.LIFX do
  use GenServer
  use Robotica.Plugin
  alias RoboticaPlugins.String
  alias Robotica.Devices.Lifx, as: RLifx

  require Logger

  import Robotica.Types

  defmodule Config do
    @type t :: %__MODULE__{
            lights: list(String.t()),
            multizone: boolean
          }
    defstruct lights: [], multizone: false
  end

  def config_schema do
    %{
      struct_type: Config,
      lights: {{:list, :string}, true},
      multizone: {{:boolean, false}, false}
    }
  end

  defmodule State do
    @type t :: %__MODULE__{
            config: Config.t(),
            tasks: %{required(String.t()) => Task.t()}
          }
    defstruct [:config, :tasks]
  end

  ## Server Callbacks

  def init(plugin) do
    {:ok, %State{config: plugin.config, tasks: %{}}}
  end

  defp light_to_string(light) do
    "Light #{light.id}/#{light.label}"
  end

  defp for_every_light(state, callback) do
    Enum.filter(Lifx.Client.devices(), &Enum.member?(state.config.lights, &1.label))
    |> Enum.map(fn light -> Task.async(fn -> callback.(light) end) end)
    |> Enum.map(fn task -> Task.await(task, :infinity) end)
  end

  defp stop_task(state, stop_list) do
    {stop_tasks, new_tasks} =
      Enum.split_with(state.tasks, fn {name, _} -> Enum.member?(stop_list, name) end)

    Enum.each(stop_tasks, fn {_, task} -> not is_nil(task) and Task.shutdown(task) end)
    %State{state | tasks: new_tasks |> Enum.into(%{})}
  end

  defp stop_all_tasks(state) do
    stop_tasks = state.tasks
    new_tasks = []
    Enum.each(stop_tasks, fn {_, task} -> not is_nil(task) and Task.shutdown(task) end)
    %State{state | tasks: new_tasks |> Enum.into(%{})}
  end

  defp get_duration(command) do
    case command.duration do
      nil -> 0
      duration -> duration * 1000
    end
  end

  defp debug_colors(colors) do
    Enum.each(colors, fn color ->
      IO.puts("---> #{inspect(color)}")
    end)

    IO.puts("")
  end

  defp set_color(light, frame, config, duration, frame_n) do
    result =
      cond do
        not is_nil(frame.colors) and config.multizone ->
          colors_index =
            case frame.colors_index do
              nil -> 0
              index -> index
            end

          case RLifx.expand_colors(frame.colors, frame_n) do
            {:ok, colors} ->
              debug_colors(colors)
              colors = %Lifx.Protocol.HSBKS{list: colors, index: colors_index}
              Lifx.Device.set_extended_color_zones_wait(light, colors, 0)

            {:error, error} ->
              Logger.info(
                "#{light_to_string(light)}: Got error in lifx expand_colors: #{inspect(error)}"
              )
          end

        not is_nil(frame.color) ->
          values = %{"frame" => frame_n}

          case RLifx.eval_color(frame.color, values) do
            {:ok, color} ->
              Lifx.Device.set_color_wait(light, color, duration)

            {:error, error} ->
              Logger.info(
                "#{light_to_string(light)}: Got error in lifx eval_color: #{inspect(error)}"
              )
          end

        true ->
          Logger.info("#{light_to_string(light)}: Got no assigned color in set_color.")
      end

    case result do
      :ok -> :ok
      {:ok, _} -> :ok
      {:error, error} -> {:error, error}
    end
  end

  defp turn_on(light, force_brightness_off \\ false) do
    color_off = %Lifx.Protocol.HSBK{
      hue: 0,
      saturation: 0,
      brightness: 0,
      kelvin: 2500
    }

    set_off_color = fn light, power ->
      Logger.debug("#{light_to_string(light)}: turn_on")

      if power == 0 or force_brightness_off do
        Lifx.Device.set_color_wait(light, color_off, 0)
      else
        {:ok, nil}
      end
    end

    with {:ok, power} <- Lifx.Device.get_power(light),
         Logger.debug("#{light_to_string(light)}: Turn on power #{power}."),
         {:ok, _} <- set_off_color.(light, power),
         {:ok, _} <- Lifx.Device.on_wait(light) do
      :ok
    else
      {:error, err} -> {:error, err}
    end
  end

  defp save_light(light, config) do
    case config.multizone do
      true ->
        with {:ok, power} <- Lifx.Device.get_power(light),
             {:ok, colors} <- Lifx.Device.get_extended_color_zones(light) do
          {:ok, {power, colors}}
        else
          {:error, error} -> {:error, error}
        end

      false ->
        with {:ok, power} <- Lifx.Device.get_power(light),
             {:ok, colors} <- Lifx.Device.get_color(light) do
          {:ok, {power, colors}}
        else
          {:error, error} -> {:error, error}
        end
    end
  end

  def restore_light(light, {power, colors}, config) do
    case config.multizone do
      true ->
        with {:ok, _} <- Lifx.Device.set_extended_color_zones_wait(light, colors, 0),
             {:ok, _} <- Lifx.Device.set_power_wait(light, power) do
          :ok
        else
          {:error, error} -> {:error, error}
        end

      false ->
        with {:ok, _} <- Lifx.Device.set_color_wait(light, colors, 0),
             {:ok, _} <- Lifx.Device.set_power_wait(light, power) do
          :ok
        else
          {:error, error} -> {:error, error}
        end
    end
  end

  defp animate(light, animation, config) do
    repeat_count =
      case animation.frames do
        [] -> 0
        _ -> animation.repeat
      end

    animate_repeat(light, animation, repeat_count, 0, config)
  end

  defp animate_repeat(_, _, repeat_count, repeat_n, _)
       when not is_nil(repeat_n) and repeat_n >= repeat_count do
    :ok
  end

  defp animate_repeat(light, animation, repeat_count, repeat_n, config) do
    case animate_frames(light, animation.frames, config) do
      :ok -> animate_repeat(light, animation, repeat_count, repeat_n + 1, config)
      {:error, error} -> {:error, error}
    end
  end

  defp animate_frames(_, [], _), do: :ok

  defp animate_frames(light, [frame | tail], config) do
    frame_count =
      case frame.repeat do
        nil -> 1
        frame_count -> frame_count
      end

    case animate_frame_repeat(light, frame, frame_count, 0, config) do
      :ok -> animate_frames(light, tail, config)
      {:error, error} -> {:error, error}
    end
  end

  defp animate_frame_repeat(_, _, frame_count, frame_n, _) when frame_n >= frame_count do
    :ok
  end

  defp animate_frame_repeat(light, frame, frame_count, frame_n, config) do
    Logger.debug("{light_to_string(light)}: setting next color")

    case set_color(light, frame, config, 0, frame_n) do
      :ok ->
        Logger.debug("{light_to_string(light)}: sleeping #{inspect(frame.sleep)}")
        Process.sleep(frame.sleep)
        animate_frame_repeat(light, frame, frame_count, frame_n + 1, config)

      {:error, error} ->
        {:error, error}
    end
  end

  @spec do_stop(state :: Config.t(), stop_list :: list | nil) :: State.t()

  defp do_stop(state, nil) do
    stop_task(state, ["default"])
  end

  defp do_stop(state, stop_list) do
    stop_task(state, stop_list)
  end

  @spec do_command(state :: Config.t(), command :: map | nil) :: State.t()

  defp do_command(state, %{action: "flash"} = command) do
    for_every_light(state, fn light ->
      Logger.debug("#{light_to_string(light)}: flash")

      with {:ok, light_state} <- save_light(light, state.config),
           :ok <- set_color(light, command, state.config, 0, 0),
           {:ok, _} <- Lifx.Device.on_wait(light),
           Process.sleep(400),
           :ok <- restore_light(light, light_state, state.config),
           Process.sleep(400),
           :ok <- set_color(light, command, state.config, 0, 0),
           Process.sleep(400),
           :ok <- restore_light(light, light_state, state.config) do
        nil
      else
        {:error, err} ->
          Logger.info("#{light_to_string(light)}: Got error in lifx flash: #{inspect(err)}")
      end
    end)

    state
  end

  defp do_command(state, %{action: "turn_off"} = command) do
    state = stop_all_tasks(state)

    for_every_light(state, fn light ->
      Logger.debug("#{light_to_string(light)}: turn_off")

      duration = get_duration(command)

      set_off =
        if duration == 0 do
          fn light ->
            Lifx.Device.off_wait(light)
          end
        else
          color_off = %Lifx.Protocol.HSBK{
            hue: 0,
            saturation: 0,
            brightness: 0,
            kelvin: 2500
          }

          fn light ->
            Lifx.Device.set_color_wait(light, color_off, duration)
          end
        end

      case set_off.(light) do
        {:ok, _} ->
          nil

        {:error, err} ->
          Logger.info("#{light_to_string(light)}: Got error in lifx turn_off: #{inspect(err)}")
      end
    end)

    state
  end

  defp do_command(state, %{action: "turn_on"} = command) do
    duration = get_duration(command)

    for_every_light(state, fn light ->
      with :ok <- turn_on(light),
           :ok <- set_color(light, command, state.config, duration, 0) do
        nil
      else
        {:error, err} ->
          Logger.info("#{light_to_string(light)}: Got error in lifx wake_up: #{inspect(err)}")
      end
    end)

    state
  end

  defp do_command(state, %{action: "animate"} = command) do
    animation =
      case command.animation do
        nil -> %{repeat: 0, frames: [], name: "default"}
        animation -> animation
      end

    stop_task(state, [animation.name])

    task =
      Task.async(fn ->
        for_every_light(state, fn light ->
          Logger.debug("#{light_to_string(light)}: animate")

          with {:ok, light_state} <- save_light(light, state.config),
               :ok <- turn_on(light, false),
               :ok <- animate(light, animation, state.config),
               :ok <- restore_light(light, light_state, state.config) do
            nil
          else
            {:error, err} ->
              Logger.info("#{light_to_string(light)}: Got error in lifx animate: #{inspect(err)}")
          end
        end)
      end)

    tasks = Map.put(state.tasks, animation.name, task)
    %State{state | tasks: tasks}
  end

  defp do_command(state, _command) do
    state
  end

  @spec handle_command(state :: Config.t(), command :: map()) :: State.t()
  defp handle_command(state, command) do
    state
    |> do_stop(get_in(command, [:stop]))
    |> do_command(command)
  end

  def handle_cast({:command, command}, state) do
    state = case Robotica.Config.validate_lights_command(command) do
      {:ok, command} -> handle_command(state, command)
      {:error, error} -> Logger.error("Invalid lifx command received: #{inspect(error)}.")
    end
    {:noreply, state}
  end

  def handle_cast({:execute, action}, state) do
    state =
      case action.lights do
        nil -> nil
        command -> handle_command(state, command)
      end

    {:noreply, state}
  end

  def handle_info({:DOWN, _ref, :process, pid, _reason}, state) do
    new_tasks = Enum.reject(state.tasks, fn {_, task_pid} -> task_pid == pid end)
    {:noreply, %State{state | tasks: new_tasks}}
  end

  def handle_info({_ref, _status}, state) do
    {:noreply, state}
  end
end
