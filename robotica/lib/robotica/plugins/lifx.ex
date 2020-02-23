defmodule Robotica.Plugins.LIFX do
  use GenServer
  use Robotica.Plugin

  require Logger

  import Robotica.Types

  defmodule Config do
    @type t :: %__MODULE__{
            lights: list(String.t())
          }
    defstruct lights: []
  end

  def config_schema do
    %{
      struct_type: Config,
      lights: {{:list, :string}, true}
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

  @spec replace_values(String.t(), %{required(String.t()) => String.t()}) :: String.t()
  defp replace_values(string, values) do
    Regex.replace(~r/{([a-z_]+)?}/, string, fn _, match ->
      Map.fetch!(values, match)
    end)
  end

  defp expand_string(string, frame_n, light_n) do
    replace_values(string, %{
      "frame" => Integer.to_string(frame_n),
      "light" => Integer.to_string(light_n)
    })
  end

  defp solve_string(string) do
    case String.split(string, "*", parts: 2) do
      [a] -> String.to_integer(a)
      [a, b] -> String.to_integer(a) * String.to_integer(b)
    end
  end

  def eval_string(string, frame_n, light_n) do
    IO.puts("IN: #{string} #{frame_n} #{light_n}")

    cond do
      is_nil(string) ->
        nil

      is_integer(string) ->
        string

      true ->
        string
        |> expand_string(frame_n, light_n)
        |> solve_string()
    end
    |> IO.inspect()
  end

  defp expand_colors(nil), do: nil

  defp expand_colors(colors, frame_n \\ 0) do
    Enum.reduce(colors, [], fn repeat, acc ->
      range =
        case eval_string(repeat.count, frame_n, 0) do
          0 -> []
          n -> 1..n
        end

      range
      |> Enum.reduce(acc, fn light_n, acc ->
        Enum.reduce(repeat.colors, acc, fn color, acc ->
          color = %Lifx.Protocol.HSBK{
            brightness: eval_string(color.brightness, frame_n, light_n),
            hue: eval_string(color.hue, frame_n, light_n),
            saturation: eval_string(color.saturation, frame_n, light_n),
            kelvin: eval_string(color.kelvin, frame_n, light_n)
          }

          [color | acc]
        end)
      end)
    end)
    |> Enum.reverse()
  end

  defp get_duration(command) do
    case command.duration do
      nil -> 0
      duration -> duration * 1000
    end
  end

  defp set_color(light, command, duration) do
    color = struct(Lifx.Protocol.HSBK, command.color)
    colors = expand_colors(command.colors)

    cond do
      not is_nil(color) ->
        Lifx.Device.set_color_wait(light, color, duration)

      not is_nil(colors) ->
        Lifx.Device.set_extended_color_zones_wait(light, colors, 0, 0, :apply)

      true ->
        color = %Lifx.Protocol.HSBK{
          hue: 0,
          saturation: 0,
          brightness: 100,
          kelvin: 2500
        }

        Lifx.Device.set_color_wait(light, color, duration)
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
    Task.shutdown(state.task)
    state = %State{state | task: nil}

    for_every_light(state, fn light ->
      Logger.debug("#{light_to_string(light)}: flash")

      with {:ok, power} <- Lifx.Device.get_power(light),
           {:ok, colors} <- Lifx.Device.get_extended_color_zones(light),
           Logger.debug("#{light_to_string(light)}: Start flash power #{power}."),
           Logger.debug("#{light_to_string(light)}: Start flash color #{inspect(colors)}."),
           {:ok, _} <- set_color(light, command, 0),
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
           {:ok, _} <- set_color(light, command, 0),
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
           {:ok, _} <- Lifx.Device.set_power_wait(light, power),
           {:ok, _} <-
             Lifx.Device.set_extended_color_zones_wait(
               light,
               colors.colors,
               colors.index,
               0,
               :apply
             ) do
        nil
      else
        {:error, err} ->
          Logger.info("#{light_to_string(light)}: Got error in lifx flash: #{inspect(err)}")
      end
    end)

    state
  end

  defp do_command(state, %{action: "turn_off"} = command) do
    not is_nil(state.task) and Task.shutdown(state.task)
    state = %State{state | task: nil}

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
    not is_nil(state.task) and Task.shutdown(state.task)
    state = %State{state | task: nil}

    duration = get_duration(command)

    for_every_light(state, fn light ->
      with :ok <- turn_on(light),
           {:ok, _} <- set_color(light, command, duration) do
        nil
      else
        {:error, err} ->
          Logger.info("#{light_to_string(light)}: Got error in lifx wake_up: #{inspect(err)}")
      end
    end)

    state
  end

  defp do_command(state, %{action: "animate"} = command) do
    not is_nil(state.task) and Task.shutdown(state.task)

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
              colors = expand_colors(frame.colors, frame_n)

              for_every_light(state, fn light ->
                turn_on(light, false)
                Lifx.Device.set_extended_color_zones_wait(light, colors, 0, 0, :apply)
              end)

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
