defmodule Robotica.Plugins.LIFX do
  use GenServer
  use Robotica.Plugins.Plugin

  defmodule State do
    @type t :: %__MODULE__{
            lights: list(String.t),
          }
    defstruct lights: %{}
  end

  ## Server Callbacks

  def init(config) do
    {:ok, config}
  end

  @spec do_command(state :: State.t(), command :: map) :: nil

  defp do_command(state, %{"action" => "flash"}) do
    lights = Enum.filter(Lifx.Client.devices, &(Enum.member?(state.lights, &1.label)))

    Enum.each(lights, &(Lifx.Device.on(&1.id)))
    Process.sleep(200)
    Enum.each(lights, &(Lifx.Device.off(&1.id)))
    Process.sleep(200)
    Enum.each(lights, &(Lifx.Device.on(&1.id)))
    Process.sleep(200)
    Enum.each(lights, &(Lifx.Device.off(&1.id)))
    Process.sleep(200)
    Enum.each(lights, &(GenServer.cast(&1.id, {:set_power, &1.power})))

    nil
  end

  defp do_command(state, %{"action" => "turn_off"}) do
    lights = Enum.filter(Lifx.Client.devices, &(Enum.member?(state.lights, &1.label)))

    Enum.each(lights, &(Lifx.Device.off(&1.id)))

    nil
  end

  defp do_command(state, %{"action" => "turn_on"}=command) do
    lights = Enum.filter(Lifx.Client.devices, &(Enum.member?(state.lights, &1.label)))

    if Map.has_key?(command, "color") do
        src_color = Map.fetch!(command, "color")
        color = %Lifx.Protocol.HSBK{
            hue: Map.fetch!(src_color, "hue"),
            saturation: Map.fetch!(src_color, "saturation"),
            brightness: Map.fetch!(src_color, "brightness"),
            kelvin: Map.fetch!(src_color, "kelvin")
        }

        Enum.each(lights, &(Lifx.Device.set_color(&1.id, color)))
    end

    Enum.each(lights, &(Lifx.Device.on(&1.id)))

    nil
  end

  defp do_command(state, %{"action" => "wake_up"}) do
    lights = Enum.filter(Lifx.Client.devices, &(Enum.member?(state.lights, &1.label)))

    Enum.each(lights, fn light -> 
        power = light.power
        if power == 0 do
            color_off = %Lifx.Protocol.HSBK{
                hue: 0, saturation: 0, brightness: 0, kelvin: 2500
            }
            Lifx.Device.set_color(light.id, color_off)
        end

        color_on = %Lifx.Protocol.HSBK{
            hue: 0, saturation: 0, brightness: 100, kelvin: 2500
        }

        Lifx.Device.on(light.id)
        Lifx.Device.set_color(light.id, color_on, 60000)
    end)

    nil
  end

  defp do_command(_state, _command) do
    nil
  end

  @spec handle_execute(state :: State.t(), action :: Robotica.Executor.Action.t()) :: nil
  defp handle_execute(state, action) do
    if Map.has_key?(action, "lights") do
      command = get_in(action, ["lights"])
      do_command(state, command)
    end
    nil
  end

  def handle_call({:wait}, _from, state) do
    {:reply, nil, state}
  end

  def handle_cast({:execute, action}, state) do
    handle_execute(state, action)
    {:noreply, state}
  end
end
