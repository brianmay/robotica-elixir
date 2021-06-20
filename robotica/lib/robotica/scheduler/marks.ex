defmodule Robotica.Scheduler.Marks do
  @moduledoc """
  Process marks in the schedule
  """
  use GenServer

  defmodule State do
    @moduledoc false
    @type t :: %__MODULE__{
            marks: %{required(String.t()) => list(RoboticaCommon.Mark)}
          }
    defstruct marks: %{}
  end

  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def put_mark(server, mark) do
    GenServer.call(server, {:put_mark, mark})
  end

  def get_mark(server, id) do
    GenServer.call(server, {:get_mark, id})
  end

  def filter_expired(state) do
    # Add several minutes margin before deleting due to late tasks.
    now =
      DateTime.utc_now()
      |> DateTime.add(-600, :second)

    marks =
      state.marks
      |> Enum.filter(fn {_id, m} -> DateTime.compare(m.stop_time, now) in [:eq, :gt] end)
      |> Enum.into(%{})

    %State{state | marks: marks}
  end

  def init(:ok) do
    {:ok, %State{}}
  end

  def handle_call({:put_mark, mark}, _from, %State{} = state) do
    state = filter_expired(state)
    id = mark.id
    {:reply, nil, put_in(state.marks[id], mark)}
  end

  def handle_call({:get_mark, id}, _from, %State{} = state) do
    state = filter_expired(state)
    mark = Map.get(state.marks, id, nil)
    {:reply, mark, state}
  end
end
