defmodule Robotica.Plugins.Lifx.FixedColor do
  @moduledoc """
  LIFX Animation that displays a fixed color
  """
  use GenServer

  alias Robotica.Devices.Lifx, as: RLifx

  defmodule Options do
    @moduledoc """
    Options for Fix Color animation
    """
    @type t :: %__MODULE__{
            sender: RLifx.callback(),
            power: integer(),
            colors: list(Robotica.Devices.Lifx.HSBKA.t())
          }
    @enforce_keys [:sender, :power, :colors]
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
    options.sender.(options.power, options.colors)
    Process.send_after(self(), :timer, 60_000)
    {:noreply, state}
  end

  @impl true
  def handle_cast(:stop, %State{} = state) do
    {:stop, :normal, state}
  end
end
