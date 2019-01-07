defmodule Robotica.Plugins.LIFX do
  use GenServer
  use Robotica.Plugins.Plugin

  require Logger

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

  @spec do_command(state :: Config.t(), command :: map) :: nil

  defp do_command(state, %{action: "flash"}) do
    for_every_light(state, fn light ->
      Logger.debug("#{light_to_string(light)}: flash")

      color_flash = %Lifx.Protocol.HSBK{
        hue: 240,
        saturation: 50,
        brightness: 100,
        kelvin: 2500
      }

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

  defp do_command(state, %{action: "turn_off"}) do
    for_every_light(state, fn light ->
      Logger.debug("#{light_to_string(light)}: turn_off")

      with {:ok, _} <- Lifx.Device.off_wait(light) do
        nil
      else
        {:error, err} ->
          Logger.info("#{light_to_string(light)}: Got error in lifx turn_off: #{inspect(err)}")
      end
    end)

    nil
  end

  defp do_command(state, %{action: "turn_on"} = command) do
    set_color = fn light, color ->
      if is_nil(color) do
        {:ok, nil}
      else
        hsbk = %Lifx.Protocol.HSBK{
          hue: color.hue,
          saturation: color.saturation,
          brightness: color.brightness,
          kelvin: color.kelvin
        }

        Lifx.Device.set_color_wait(light, hsbk, 0)
      end
    end

    for_every_light(state, fn light ->
      Logger.debug("#{light_to_string(light)}: turn_on")

      with {:ok, _} <- set_color.(light, command.color),
           {:ok, _} <- Lifx.Device.on_wait(light) do
        nil
      else
        {:error, err} ->
          Logger.info("#{light_to_string(light)}: Got error in lifx turn_on: #{inspect(err)}")
      end
    end)

    nil
  end

  defp do_command(state, %{action: "wake_up"}) do
    color_off = %Lifx.Protocol.HSBK{
      hue: 0,
      saturation: 0,
      brightness: 0,
      kelvin: 2500
    }

    color_on = %Lifx.Protocol.HSBK{
      hue: 0,
      saturation: 0,
      brightness: 100,
      kelvin: 2500
    }

    set_color = fn light, power, color ->
      Logger.debug("#{light_to_string(light)}: wake_up")

      if power == 0 do
        Lifx.Device.set_color_wait(light, color, 0)
      else
        {:ok, nil}
      end
    end

    for_every_light(state, fn light ->
      with {:ok, power} <- Lifx.Device.get_power(light),
           Logger.debug("#{light_to_string(light)}: Start wake_up power #{power}."),
           {:ok, _} <- set_color.(light, power, color_off),
           {:ok, _} <- Lifx.Device.on_wait(light),
           {:ok, _} <- Lifx.Device.set_color_wait(light, color_on, 60000) do
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

  @spec handle_execute(state :: Config.t(), action :: Robotica.Plugins.Action.t()) :: nil
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
