defmodule Robotica.PluginRegistry do
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

  @spec lookup(locations :: list(String.t()), devices :: list(String.t())) ::
          list(pid)
  def lookup(locations, devices) do
    GenServer.call(Robotica.PluginRegistry, {:lookup, locations, devices})
  end

  @spec add(location :: String.t(), device :: String.t(), pid :: pid) :: :ok
  def add(location, device, pid) do
    GenServer.call(Robotica.PluginRegistry, {:add, location, device, pid})
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

    %State{state | plugins: new_plugins}
  end

  @spec get_required_plugins(
          state :: State.t(),
          locations :: list(String.t()),
          devices :: list(String.t()) | nil
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

  def handle_call({:lookup, locations, devices}, _from, state) do
    pids = get_required_plugins(state, locations, devices)
    {:reply, pids, state}
  end

  def handle_call({:add, location, device, pid}, _from, state) do
    new_state = handle_add(state, location, device, pid)
    {:reply, :ok, new_state}
  end

  @spec keyword_list_to_map(values :: list) :: map
  defp keyword_list_to_map(values) do
    for {key, val} <- values, into: %{}, do: {key, val}
  end

  @spec delete_pid_from_list(list, pid) :: list
  defp delete_pid_from_list(list, pid) do
    Enum.reject(list, fn {_, list_pid} -> list_pid == pid end)
  end

  def handle_info({:DOWN, _ref, :process, pid, _reason}, state) do
    new_plugins =
      state.plugins
      |> Enum.map(fn {location, l} -> {location, delete_pid_from_list(l, pid)} end)
      |> keyword_list_to_map()

    new_state = %State{state | plugins: new_plugins}

    {:noreply, new_state}
  end
end
