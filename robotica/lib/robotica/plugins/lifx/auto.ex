defmodule Robotica.Plugins.Lifx.Auto do
  @moduledoc """
  LIFX Animation that displays a time dependant color
  """
  use GenServer

  alias Robotica.Devices.Lifx, as: RLifx
  alias Robotica.Devices.Lifx.HSBKA

  defmodule Options do
    @moduledoc """
    Options for Auto animation
    """
    @type t :: %__MODULE__{
            sender: RLifx.callback(),
            number: integer()
          }
    @enforce_keys [:sender, :number]
    defstruct @enforce_keys
  end

  defmodule State do
    @moduledoc false
    @type t :: %__MODULE__{
            options: Options.t()
          }
    @enforce_keys [:options]
    defstruct @enforce_keys
  end

  def start(%Options{} = options) do
    GenServer.start(__MODULE__, options)
  end

  @impl true
  def init(%Options{} = options) do
    state = %State{
      options: options
    }

    Process.send_after(self(), :timer, 0)
    {:ok, state}
  end

  @impl true
  def handle_info(:timer, %State{options: options} = state) do
    {power, colors} = get_power_colors(options.number)
    options.sender.(power, colors)
    Process.send_after(self(), :timer, 60_000)
    {:noreply, state}
  end

  @impl true
  def handle_cast(:stop, %State{} = state) do
    {:stop, :normal, state}
  end

  @spec get_power_colors(integer()) :: {integer(), list(HSBKA.t())}
  defp get_power_colors(number) do
    timezone = RoboticaCommon.Date.get_timezone()
    now = DateTime.now!(timezone)

    color =
      case now.hour do
        h when h > 22 or h < 5 ->
          %HSBKA{hue: 0, saturation: 0, brightness: 5, kelvin: 1000}

        h when h > 21 or h < 6 ->
          %HSBKA{hue: 0, saturation: 0, brightness: 15, kelvin: 1500}

        h when h > 20 or h < 7 ->
          %HSBKA{hue: 0, saturation: 0, brightness: 25, kelvin: 2000}

        h when h > 19 or h < 8 ->
          %HSBKA{hue: 0, saturation: 0, brightness: 50, kelvin: 2500}

        h when h > 18 or h < 9 ->
          %HSBKA{hue: 0, saturation: 0, brightness: 100, kelvin: 3000}

        _ ->
          %HSBKA{hue: 0, saturation: 0, brightness: 100, kelvin: 3500}
      end

    power = 65_535
    colors = replicate(color, number)

    {power, colors}
  end

  @spec replicate(any(), integer()) :: list(any())
  defp replicate(x, n), do: for(i <- 0..n, i > 0, do: x)
end
