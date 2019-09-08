defmodule Robotica.Plugins.LIFX do
  use GenServer
  use RoboticaPlugins.Plugin

  require Logger

  import Robotica.Types

  defmodule Config do
    @type t :: %__MODULE__{
            lights: list(String.t())
          }
    defstruct lights: []
  end

  ## Server Callbacks

  def init(plugin) do
    {:ok, plugin.config}
  end

  def config_schema do
    %{
      struct_type: Config,
      lights: {{:list, :string}, true}
    }
  end

  defp light_to_string(light) do
    "Light #{light.id}/#{light.label}"
  end

  defp for_every_light(state, callback) do
    lights = Enum.filter(Lifx.Client.devices(), &Enum.member?(state.lights, &1.label))
    Enum.each(lights, callback)
  end

  defp get_color(command) do
    case command.color do
      nil ->
        %Lifx.Protocol.HSBK{
          hue: 0,
          saturation: 0,
          brightness: 100,
          kelvin: 2500
        }

      color ->
        %Lifx.Protocol.HSBK{
          hue: color.hue,
          saturation: color.saturation,
          brightness: color.brightness,
          kelvin: color.kelvin
        }
    end
  end

  defp get_duration(command) do
    case command.duration do
      nil -> 0
      duration -> duration * 1000
    end
  end

  @spec do_command(state :: Config.t(), command :: map) :: nil

  defp do_command(state, %{action: "flash"} = command) do
    for_every_light(state, fn light ->
      Logger.debug("#{light_to_string(light)}: flash")

      color_flash = get_color(command)

      with {:ok, power} <- Lifx.Device.get_power(light),
           {:ok, color} <- Lifx.Device.get_color(light),
           Logger.debug("#{light_to_string(light)}: Start flash power #{power}."),
           Logger.debug("#{light_to_string(light)}: Start flash color #{inspect(color)}."),
           {:ok, _} <- Lifx.Device.set_color_wait(light, color_flash, 0),
           {:ok, _} <- Lifx.Device.on_wait(light),
           Process.sleep(400),
           {:ok, _} <- Lifx.Device.set_color_wait(light, color, 0),
           Process.sleep(200),
           {:ok, _} <- Lifx.Device.set_color_wait(light, color_flash, 0),
           Process.sleep(400),
           {:ok, _} <- Lifx.Device.set_color_wait(light, color, 0),
           Process.sleep(200),
           {:ok, _} <- Lifx.Device.set_power_wait(light, power),
           {:ok, _} <- Lifx.Device.set_color_wait(light, color, 0) do
        nil
      else
        {:error, err} ->
          Logger.info("#{light_to_string(light)}: Got error in lifx flash: #{inspect(err)}")
      end
    end)

    nil
  end

  defp do_command(state, %{action: "turn_off"} = command) do
    for_every_light(state, fn light ->
      Logger.debug("#{light_to_string(light)}: turn_off")

      duration = get_duration(command)
      IO.puts(duration)

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

      with {:ok, _} <- set_off.(light) do
        nil
      else
        {:error, err} ->
          Logger.info("#{light_to_string(light)}: Got error in lifx turn_off: #{inspect(err)}")
      end
    end)

    nil
  end

  defp do_command(state, %{action: "turn_on"} = command) do
    color_off = %Lifx.Protocol.HSBK{
      hue: 0,
      saturation: 0,
      brightness: 0,
      kelvin: 2500
    }

    color_on = get_color(command)
    duration = get_duration(command)

    set_off_color = fn light, power, color ->
      Logger.debug("#{light_to_string(light)}: turn_on")

      if power == 0 do
        Lifx.Device.set_color_wait(light, color, 0)
      else
        {:ok, nil}
      end
    end

    for_every_light(state, fn light ->
      with {:ok, power} <- Lifx.Device.get_power(light),
           Logger.debug("#{light_to_string(light)}: Start wake_up power #{power}."),
           {:ok, _} <- set_off_color.(light, power, color_off),
           {:ok, _} <- Lifx.Device.on_wait(light),
           {:ok, _} <- Lifx.Device.set_color_wait(light, color_on, duration) do
        nil
      else
        {:error, err} ->
          Logger.info("#{light_to_string(light)}: Got error in lifx wake_up: #{inspect(err)}")
      end
    end)

    nil
  end

  defp do_command(_state, _command) do
    nil
  end

  @spec handle_execute(state :: Config.t(), action :: RoboticaPlugins.Action.t()) :: nil
  defp handle_execute(state, action) do
    case action.lights do
      %{} = lights ->
        do_command(state, lights)

      _ ->
        nil
    end

    nil
  end

  def handle_cast({:execute, action}, state) do
    handle_execute(state, action)
    {:noreply, state}
  end
end
