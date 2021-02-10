defmodule RoboticaUi.Schedule do
  use GenServer
  use RoboticaPlugins.EventBus

  defmodule State do
    @type t :: %__MODULE__{
            scenes: list(GenServer.server()),
            schedule: list(Robotica.Types.ScheduledStep.t())
          }
    defstruct scenes: [], schedule: []
  end

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def init(_) do
    event_params = %{topic: :request_schedule}

    EventSource.notify event_params do
      nil
    end

    {:ok, %State{}}
  end

  @spec register(GenServer.server()) :: nil
  def register(pid) do
    GenServer.call(__MODULE__, {:register, pid})
  end

  def set_schedule(schedule) do
    GenServer.call(__MODULE__, {:set_schedule, schedule})
  end

  def get_schedule() do
    GenServer.call(__MODULE__, {:get_schedule})
  end

  def get_tasks_by_id(id) do
    GenServer.call(__MODULE__, {:get_tasks_by_id, id})
  end

  def handle_call({:register, pid}, _from, state) do
    Process.monitor(pid)
    state = %State{state | scenes: [pid | state.scenes]}
    {:reply, nil, state}
  end

  def handle_call({:set_schedule, schedule}, _, state) do
    Enum.each(state.scenes, fn pid ->
      try do
        Scenic.Scene.send_event(pid, {:schedule, schedule})
      catch
        :exit, {:noproc, _} -> nil
      end
    end)

    {:reply, nil, Map.put(state, :schedule, schedule)}
  end

  def handle_call({:get_schedule}, _, state) do
    {:reply, {:ok, state.schedule}, state}
  end

  def handle_call({:get_tasks_by_id, id}, _, state) do
    tasks =
      state.schedule
      |> Enum.map(fn step ->
        tasks = Enum.filter(step.tasks, fn task -> task.id == id end)
        %{step | tasks: tasks}
      end)
      |> Enum.filter(fn step -> length(step.tasks) > 0 end)

    {:reply, {:ok, tasks}, state}
  end

  def handle_info({:DOWN, _ref, :process, pid, _reason}, state) do
    state = %State{state | scenes: List.delete(state.scenes, pid)}
    {:noreply, state}
  end
end
