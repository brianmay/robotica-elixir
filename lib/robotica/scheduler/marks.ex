defmodule Robotica.Scheduler.Marks do
  use GenServer

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
      |> Calendar.DateTime.subtract!(600)

    state
    |> Enum.filter(fn {_id, m} -> DateTime.compare(m.expires_time, now) in [:eq, :gt] end)
    |> Enum.into(%{})
  end

  def init(:ok) do
    {:ok, %{}}
  end

  def handle_call({:put_mark, mark}, _from, state) do
    state = filter_expired(state)
    id = mark.id
    {:reply, nil, Map.put(state, id, mark)}
  end

  def handle_call({:get_mark, id}, _from, state) do
    state = filter_expired(state)
    mark = Map.get(state, id, nil)
    {:reply, mark, state}
  end
end
