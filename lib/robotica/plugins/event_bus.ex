defmodule Robotica.Plugins.EventBus do
  use GenServer
  use Robotica.Plugins.Plugin
  use EventBus.EventSource
  require Logger

  defmodule State do
    @type t :: %__MODULE__{}
    defstruct []
  end

  ## Server Callbacks

  def init(plugin) do
    EventBus.register_topic(:execute)
    EventBus.register_topic(:done)
    {:ok, plugin}
  end

  def handle_call({:wait}, _from, state) do
    {:reply, nil, state}
  end

  def handle_cast({:execute, action}, state) do
    event_params = %{topic: :execute}
    EventSource.notify event_params do
      action
    end

    Process.sleep(10000)

    event_params = %{topic: :done}
    EventSource.notify event_params do
      action
    end

    {:noreply, state}
  end
end
