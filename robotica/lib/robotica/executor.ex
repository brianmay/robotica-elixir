defmodule Robotica.Executor do
  use GenServer
  use EventBus.EventSource

  defmodule State do
    @type t :: %__MODULE__{
          }
    defstruct []
  end

  ## Client API

  @spec start_link(opts :: list) :: {:ok, pid} | {:error, String.t()}
  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
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

  @spec get_required_plugins(
          state :: State.t(),
          locations :: list(String.t()),
          devices :: list(String.t())
        ) :: list(pid)
  defp get_required_plugins(_state, locations, devices) do
    Robotica.PluginRegistry.lookup(locations, devices)
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

    if task.devices == nil or Enum.member?(task.devices, "Robotica") do
      EventSource.notify %{topic: :execute} do
        task
      end
    end

    Enum.each(plugins, fn pid ->
      Robotica.Plugin.execute(pid, action)
    end)

    Enum.each(plugins, fn pid ->
      Robotica.Plugin.wait(pid)
    end)

    nil
  end

  def handle_cast({:execute, task}, state) do
    handle_execute(state, task)
    {:noreply, state}
  end

end
