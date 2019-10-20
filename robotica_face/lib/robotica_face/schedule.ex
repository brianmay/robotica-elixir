defmodule RoboticaFace.Schedule do
  use GenServer
  use EventBus.EventSource

  defmodule State do
    @type t :: %__MODULE__{
            scenes: list(GenServer.server()),
            schedule: list(Robotica.Types.MultiStep.t())
          }
    defstruct scenes: [], schedule: []
  end

  def start_link(default) do
    name = default[:name]
    GenServer.start_link(__MODULE__, nil, name: name)
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
    GenServer.call(:face_schedule, {:register, pid})
  end

  def set_schedule(schedule) do
    GenServer.call(:face_schedule, {:set_schedule, schedule})
  end

  def get_schedule() do
    GenServer.call(:face_schedule, {:get_schedule})
  end

  def get_tasks_by_id(id) do
    GenServer.call(:face_schedule, {:get_tasks_by_id, id})
  end

  def handle_call({:register, pid}, _from, state) do
    Process.monitor(pid)
    state = %State{state | scenes: [pid | state.scenes]}
    {:reply, nil, state}
  end

  def handle_call({:set_schedule, schedule}, _, state) do
    Enum.each(state.scenes, fn pid ->
      GenServer.cast(pid, {:schedule, schedule})
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
