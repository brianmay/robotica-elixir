defmodule Robotica.Plugins.LIFX do
  use GenServer
  use Robotica.Plugins.Plugin

  defmodule State do
    @type t :: %__MODULE__{
            lights: list(String.t())
          }
    defstruct lights: []
  end

  ## Server Callbacks

  def init(plugin) do
    {:ok, plugin.config}
  end

  @spec do_command(state :: State.t(), command :: map) :: nil

  defp do_command(state, %{action: "flash"}) do
    lights = Enum.filter(Lifx.Client.devices(), &Enum.member?(state.lights, &1.label))
    Enum.each(lights, &Lifx.Device.get_power(&1))

    lights = Enum.filter(Lifx.Client.devices(), &Enum.member?(state.lights, &1.label))
    Enum.each(lights, &Lifx.Device.on_wait(&1))
    Process.sleep(200)
    Enum.each(lights, &Lifx.Device.off_wait(&1))
    Process.sleep(200)
    Enum.each(lights, &Lifx.Device.on_wait(&1))
    Process.sleep(200)
    Enum.each(lights, &Lifx.Device.off_wait(&1))
    Process.sleep(200)
    Enum.each(lights, &Lifx.Device.set_power_wait(&1, &1.power))

    nil
  end

  defp do_command(state, %{action: "turn_off"}) do
    lights = Enum.filter(Lifx.Client.devices(), &Enum.member?(state.lights, &1.label))

    Enum.each(lights, &Lifx.Device.off_wait(&1))

    nil
  end

  defp do_command(state, %{action: "turn_on"} = command) do
    lights = Enum.filter(Lifx.Client.devices(), &Enum.member?(state.lights, &1.label))

    if Map.has_key?(command, "color") do
      src_color = Map.fetch!(command, "color")

      color = %Lifx.Protocol.HSBK{
        hue: Map.fetch!(src_color, "hue"),
        saturation: Map.fetch!(src_color, "saturation"),
        brightness: Map.fetch!(src_color, "brightness"),
        kelvin: Map.fetch!(src_color, "kelvin")
      }

      Enum.each(lights, &Lifx.Device.set_color_wait(&1, color, 0))
    end

    Enum.each(lights, &Lifx.Device.on_wait(&1))

    nil
  end

  defp do_command(state, %{action: "wake_up"}) do
    lights = Enum.filter(Lifx.Client.devices(), &Enum.member?(state.lights, &1.label))

    Enum.each(lights, fn light ->
      with {:ok, power} <- Lifx.Device.get_power(light) do
        if power == 0 do
          color_off = %Lifx.Protocol.HSBK{
            hue: 0,
            saturation: 0,
            brightness: 0,
            kelvin: 2500
          }

          Lifx.Device.set_color_wait(light, color_off, 0)
        end

        color_on = %Lifx.Protocol.HSBK{
          hue: 0,
          saturation: 0,
          brightness: 100,
          kelvin: 2500
        }

        Lifx.Device.on_wait(light)
        Lifx.Device.set_color_wait(light, color_on, 60000)
      else
        _ -> nil
      end
    end)

    nil
  end

  defp do_command(_state, _command) do
    nil
  end

  @spec handle_execute(state :: State.t(), action :: Robotica.Executor.Action.t()) :: nil
  defp handle_execute(state, action) do
    case action.lights do
      %{} = lights ->
        do_command(state, lights)

      _ ->
        nil
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
