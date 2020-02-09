defmodule Robotica.Executor do
  use GenServer

  defmodule State do
    @type t :: %__MODULE__{
            plugins: %{required(String.t()) => list({String.t(), pid})}
          }
    defstruct plugins: %{}
  end

  ## Client API

  @spec start_link(opts :: list) :: {:ok, pid} | {:error, String.t()}
  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  @spec lookup(server :: pid | atom, locations :: list(String.t()), devices :: list(String.t())) ::
          list(pid)
  def lookup(server, locations, devices) do
    GenServer.call(server, {:lookup, locations, devices})
  end

  @spec add(server :: pid | atom, location :: String.t(), device :: String.t(), pid :: pid) :: nil
  def add(server, location, device, pid) do
    GenServer.call(server, {:add, location, device, pid})
    nil
  end

  @spec execute(server :: pid | atom, task :: RoboticaPlugins.Task.t()) :: nil
  def execute(server, %RoboticaPlugins.Task{} = task) do
    GenServer.cast(server, {:execute, task})
    nil
  end

  ## Server Callbacks

  def init(:ok) do
    {:ok, %State{}}
  end

  @spec handle_add(state :: State.t(), location :: String.t(), device :: String.t(), pid :: pid) ::
          State.t()
  defp handle_add(state, location, device, pid) do
    list = Map.get(state.plugins, location, [])
    list = [{device, pid} | list]
    new_plugins = Map.put(state.plugins, location, list)

    _ref = Process.monitor(pid)

    state
    |> Map.put(:plugins, new_plugins)
  end

  @spec get_required_plugins(
          state :: State.t(),
          locations :: list(String.t()),
          devices :: list(String.t())
        ) :: list(pid)
  defp get_required_plugins(state, locations, devices) do
    locations
    |> Enum.map(fn location ->
      state.plugins
      |> Map.get(location, [])
      |> Enum.filter(fn {device, _} -> devices == nil or Enum.member?(devices, device) end)
      |> Enum.map(fn {_, pid} -> pid end)
    end)
    |> List.flatten()
  end

  @spec handle_execute(
          state :: State.t(),
          task :: RoboticaPlugins.Task.t()
        ) :: nil
  defp handle_execute(state, task) do
    locations = task.locations
    devices = task.devices
    action = task.action

    plugins = get_required_plugins(state, locations, devices)

    Enum.each(plugins, fn pid ->
      Robotica.Plugin.execute(pid, action)
    end)

    Enum.each(plugins, fn pid ->
      Robotica.Plugin.wait(pid)
    end)

    nil
  end

  def handle_call({:lookup, locations, devices}, _from, state) do
    pids = get_required_plugins(state, locations, devices)
    {:reply, pids, state}
  end

  def handle_call({:add, location, device, pid}, _from, state) do
    new_state = handle_add(state, location, device, pid)
    {:reply, nil, new_state}
  end

  def handle_cast({:execute, task}, state) do
    handle_execute(state, task)
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
