defmodule Robotica.Plugins.MQTT do
  use GenServer
  use Robotica.Plugin
  require Logger

  defmodule Config do
    @type t :: %__MODULE__{}
    defstruct []
  end

  ## Server Callbacks

  def init(plugin) do
    {:ok, plugin}
  end

  def config_schema do
    %{
      struct_type: Config
    }
  end

  def handle_command({:command, _command}, state) do
    # Do nothing for now
    {:noreply, state}
  end

  def handle_cast({:execute, action}, state) do
    case Robotica.Mqtt.publish_action(state.location, action) do
      :ok -> nil
      {:error, _} -> Logger.debug("Cannot send outgoing action #{inspect(action)}.")
    end

    {:noreply, state}
  end
end
