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
            task: Task.t() | nil
          }
    defstruct [:config, :task]
  end

  ## Server Callbacks

  def init(plugin) do
    {:ok, %State{config: plugin.config, task: nil}}
  end

  defp light_to_string(light) do
    "Light #{light.id}/#{light.label}"
  end

  defp for_every_light(state, callback) do
    lights = Enum.filter(Lifx.Client.devices(), &Enum.member?(state.config.lights, &1.label))
    Enum.each(lights, callback)
  end

  defp repeat(repeats, default, callback, n \\ 0)

  defp repeat(0, _, _, _), do: nil

  defp repeat(repeats, default, callback, n) do
    new_repeats =
      case repeats do
        nil -> default
        r -> r - 1
      end

    callback.(n)
    repeat(new_repeats, default, callback, n + 1)
  end

  defp stop_task(state) do
    not is_nil(state.task) and Task.shutdown(state.task)
    %State{state | task: nil}
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
          case RLifx.expand_colors(frame.colors, frame_n) do
            {:ok, colors} ->
              debug_colors(colors)
              Lifx.Device.set_extended_color_zones_wait(light, colors, 0, 0, :apply)

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

  defp turn_off(light) do
    Lifx.Device.off_wait(light)
  end

  @spec do_command(state :: Config.t(), command :: map) :: State.t()

  defp do_command(state, %{action: "flash"} = command) do
    state = stop_task(state)

    for_every_light(state, fn light ->
      Logger.debug("#{light_to_string(light)}: flash")

      with {:ok, power} <- Lifx.Device.get_power(light),
           {:ok, colors} <- Lifx.Device.get_extended_color_zones(light),
           Logger.debug("#{light_to_string(light)}: Start flash power #{power}."),
           Logger.debug("#{light_to_string(light)}: Start flash color #{inspect(colors)}."),
           :ok <- set_color(light, command, state.config, 0, 0),
           {:ok, _} <- Lifx.Device.on_wait(light),
           Process.sleep(400),
           {:ok, _} <-
             Lifx.Device.set_extended_color_zones_wait(
               light,
               colors.colors,
               colors.index,
               0,
               :apply
             ),
           Process.sleep(400),
           :ok <- set_color(light, command, state.config, 0, 0),
           Process.sleep(400),
           {:ok, _} <-
             Lifx.Device.set_extended_color_zones_wait(
               light,
               colors.colors,
               colors.index,
               0,
               :apply
             ),
           Process.sleep(400),
           {:ok, _} <- Lifx.Device.set_power_wait(light, power) do
        nil
      else
        {:error, err} ->
          Logger.info("#{light_to_string(light)}: Got error in lifx flash: #{inspect(err)}")
      end
    end)

    state
  end

  defp do_command(state, %{action: "turn_off"} = command) do
    state = stop_task(state)

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
    state = stop_task(state)

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
    state = stop_task(state)

    animation =
      case command.animation do
        nil -> %{repeat: 0, frames: []}
        animation -> animation
      end

    repeat =
      case animation.frames do
        [] -> 0
        _ -> animation.repeat
      end

    for_every_light(state, fn light ->
      turn_on(light, true)
    end)

    task =
      Task.async(fn ->
        repeat(repeat, nil, fn _count ->
          Enum.each(animation.frames, fn frame ->
            repeat(frame.repeat, 0, fn frame_n ->
              Logger.debug("Setting light")

              for_every_light(state, fn light ->
                set_color(light, frame, state.config, 0, frame_n)
              end)

              Logger.debug("sleeping #{inspect(frame.sleep)}")
              Process.sleep(frame.sleep)
            end)
          end)
        end)

        for_every_light(state, fn light ->
          turn_off(light)
        end)
      end)

    %State{state | task: task}
  end

  defp do_command(state, _command) do
    state
  end

  @spec handle_execute(state :: Config.t(), action :: RoboticaPlugins.Action.t()) :: State.t()
  defp handle_execute(state, action) do
    case action.lights do
      %{} = lights ->
        do_command(state, lights)

      _ ->
        state
    end
  end

  def handle_cast({:execute, action}, state) do
    state = handle_execute(state, action)
    {:noreply, state}
  end

  def handle_info({:DOWN, _ref, :process, pid, _reason}, state) do
    state =
      if state.task.pid == pid do
        %State{state | task: nil}
      else
        state
      end

    {:noreply, state}
  end

  def handle_info({_ref, _status}, state) do
    {:noreply, state}
  end
end
