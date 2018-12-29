defmodule Robotica.Executor do
  use GenServer

  defmodule State do
    @type t :: %__MODULE__{
            plugins: %{required(String.t()) => list(pid)}
          }
    defstruct plugins: %{}
  end

  defmodule Mark do
    @type t :: %__MODULE__{
            id: String.t(),
            status: :done | :cancelled,
            expires_time: %DateTime{}
          }
    @enforce_keys [:id, :status, :expires_time]
    defstruct id: nil,
              status: nil,
              expires_time: nil
  end

  defmodule Task do
    @type t :: %__MODULE__{
            locations: list(String.t()),
            action: Robotica.Plugins.Action.t(),
            frequency: :daily | :weekly | nil,
            id: String.t() | nil,
            mark: Mark.t() | nil
          }
    @enforce_keys [:locations, :action, :frequency, :mark]
    defstruct locations: [], action: nil, frequency: nil, id: nil, mark: nil
  end

  ## Client API

  @spec start_link(opts :: list) :: {:ok, pid} | {:error, String.t()}
  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  @spec lookup(server :: pid | atom, location :: String.t()) :: list(pid)
  def lookup(server, location) do
    GenServer.call(server, {:lookup, location})
  end

  @spec add(server :: pid | atom, location :: String.t(), pid :: pid) :: nil
  def add(server, location, pid) do
    GenServer.call(server, {:add, location, pid})
    nil
  end

  @spec execute(server :: pid | atom, task :: Task.t()) :: nil
  def execute(server, %Task{locations: locations, action: action}) do
    GenServer.cast(server, {:execute, locations, action})
    nil
  end

  ## Server Callbacks

  def init(:ok) do
    {:ok, %State{}}
  end

  @spec handle_add(state :: State.t(), location :: String.t(), pid :: pid) :: State.t()
  def handle_add(state, location, pid) do
    list = Map.get(state.plugins, location, [])
    list = [pid | list]
    new_plugins = Map.put(state.plugins, location, list)

    _ref = Process.monitor(pid)

    state
    |> Map.put(:plugins, new_plugins)
  end

  @spec handle_execute(
          state :: State.t(),
          locations :: list(String.t()),
          action :: Robotica.Plugins.Action.t()
        ) :: nil
  defp handle_execute(state, locations, action) do
    Enum.each(locations, fn location ->
      plugins = Map.get(state.plugins, location, [])

      Enum.each(plugins, fn pid ->
        Robotica.Plugins.execute(pid, action)
      end)

      Enum.each(plugins, fn pid ->
        Robotica.Plugins.wait(pid)
      end)
    end)

    nil
  end

  def handle_call({:lookup, location}, _from, state) do
    {:reply, Map.get(state.plugins, location, []), state}
  end

  def handle_call({:add, location, pid}, _from, state) do
    new_state = handle_add(state, location, pid)
    {:reply, nil, new_state}
  end

  def handle_cast({:execute, locations, action}, state) do
    handle_execute(state, locations, action)
    {:noreply, state}
  end

  @spec keyword_list_to_map(values :: list) :: map
  defp keyword_list_to_map(values) do
    for {key, val} <- values, into: %{}, do: {key, val}
  end

  def handle_info({:DOWN, _ref, :process, pid, _reason}, state) do
    new_plugins =
      state.plugins
      |> Enum.map(fn {_location, l} -> List.delete(l, pid) end)
      |> keyword_list_to_map()

    new_state =
      state
      |> Map.put(:plugins, new_plugins)

    {:noreply, new_state}
  end
end
