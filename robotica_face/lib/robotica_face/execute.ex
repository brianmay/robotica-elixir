defmodule RoboticaFace.Execute do
  @moduledoc false

  use GenServer
  require Logger

  defmodule State do
    @type t :: %__MODULE__{
            scenes: list(GenServer.server())
          }
    defstruct scenes: []
  end

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def init(_opts) do
    {:ok, %State{}}
  end

  def config_schema do
    %{}
  end

  @spec register(GenServer.server()) :: nil
  def register(pid) do
    GenServer.cast(__MODULE__, {:register, pid})
  end

  def execute(action) do
    GenServer.cast(__MODULE__, {:execute, action})
  end

  def handle_cast({:execute, action}, state) do
    Enum.each(state.scenes, fn pid ->
      GenServer.cast(pid, {:execute, action})
    end)

    {:noreply, state}
  end

  def handle_cast({:register, pid}, state) do
    Process.monitor(pid)
    state = %State{state | scenes: [pid | state.scenes]}
    Logger.info("register web scene #{inspect(pid)} #{inspect(state.scenes)}")
    {:noreply, state}
  end

  def handle_info({:DOWN, _ref, :process, pid, _reason}, state) do
    state = %State{state | scenes: List.delete(state.scenes, pid)}
    Logger.info("unregister web scene #{inspect(pid)} #{inspect(state.scenes)}")
    {:noreply, state}
  end
end
