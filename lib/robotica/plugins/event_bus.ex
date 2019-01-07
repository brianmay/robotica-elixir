defmodule Robotica.Plugins.EventBus do
  use GenServer
  use Robotica.Plugins.Plugin
  use EventBus.EventSource
  require Logger

  defmodule Config do
    @type t :: %__MODULE__{}
    defstruct []
  end

  ## Server Callbacks

  def init(plugin) do
    EventBus.register_topic(:execute)
    {:ok, plugin.config}
  end

  def config_schema do
    %{
      struct_type: Config
    }
  end

  def handle_cast({:execute, action}, state) do
    event_params = %{topic: :execute}

    EventSource.notify event_params do
      action
    end

    {:noreply, state}
  end
end
