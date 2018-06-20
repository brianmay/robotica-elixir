defmodule Robotica.Registry do
  use GenServer

  defmodule State do
    @type t :: %__MODULE__{
            plugins: %{required(String.t()) => list(pid)},
            refs: %{required(String.t()) => pid}
          }
    defstruct plugins: %{}, refs: %{}
  end

  ## Client API

  @doc """
  Starts the registry.
  """
  @spec start_link(opts :: list) :: {:ok, pid} | {:error, String.t()}
  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  @doc """
  Looks up the bucket pid for `name` stored in `server`.

  Returns `{:ok, pid}` if the bucket exists, `:error` otherwise.
  """
  def lookup(server, location) do
    GenServer.call(server, {:lookup, location})
  end

  @doc """
  Ensures there is a bucket associated with the given `name` in `server`.
  """
  def add(server, location, pid) do
    GenServer.call(server, {:add, location, pid})
  end

  ## Server Callbacks

  def init(:ok) do
    {:ok, %State{}}
  end

  def handle_call({:lookup, location}, _from, state) do
    {:reply, Map.get(state.plugins, location, []), state}
  end

  def handle_call({:add, location, pid}, _from, state) do
    list = Map.get(state.plugins, location, [])
    list = [pid | list]
    new_plugins = Map.put(state.plugins, location, list)

    ref = Process.monitor(pid)
    new_refs = Map.put(state.refs, ref, pid)

    new_state =
      state
      |> Map.put(:plugins, new_plugins)
      |> Map.put(:refs, new_refs)

    {:reply, nil, new_state}
  end

  @spec keyword_list_to_map(values :: list) :: map
  defp keyword_list_to_map(values) do
    for {key, val} <- values, into: %{}, do: {key, val}
  end

  def handle_info({:DOWN, ref, :process, _pid, _reason}, state) do
    {name, new_refs} = Map.pop(state.refs, ref)

    new_plugins =
      state.plugins
      |> Enum.map(fn {_location, l} -> List.delete(l, name) end)
      |> keyword_list_to_map()

    new_state =
      state
      |> Map.put(:plugins, new_plugins)
      |> Map.put(:refs, new_refs)

    {:noreply, new_state}
  end
end
