defmodule RoboticaFace.Tesla do
  @moduledoc false

  use GenServer
  require Logger

  defmodule State do
    @type t :: %__MODULE__{
            tesla_state: map(),
            scenes: list(GenServer.server())
          }
    defstruct tesla_state: %{}, scenes: []
  end

  def start_link(default) do
    name = default[:name]
    GenServer.start_link(__MODULE__, nil, name: name)
  end

  def init(_opts) do
    {:ok, %State{}}
  end

  def config_schema do
    %{}
  end

  @spec register(GenServer.server()) :: nil
  def register(pid) do
    GenServer.cast(:tesla, {:register, pid})
  end

  def update_tesla_state(tesla_state) do
    GenServer.cast(:tesla, {:update_tesla_state, tesla_state})
  end

  def get_tesla_state() do
    GenServer.call(:tesla, :get_tesla_state)
  end

  def handle_cast({:update_tesla_state, tesla_state}, state) do
    Enum.each(state.scenes, fn pid ->
      GenServer.cast(pid, {:update_tesla_state, tesla_state})
    end)

    {:noreply, %{state | tesla_state: tesla_state}}
  end

  def handle_cast({:register, pid}, state) do
    Process.monitor(pid)
    state = %State{state | scenes: [pid | state.scenes]}
    Logger.info("register web scene #{inspect(pid)} #{inspect(state.scenes)}")
    {:noreply, state}
  end

  def handle_call(:get_tesla_state, _from, state) do
    {:reply, state.tesla_state, state}
  end

  def handle_info({:DOWN, _ref, :process, pid, _reason}, state) do
    state = %State{state | scenes: List.delete(state.scenes, pid)}
    Logger.info("unregister web scene #{inspect(pid)} #{inspect(state.scenes)}")
    {:noreply, state}
  end
end
