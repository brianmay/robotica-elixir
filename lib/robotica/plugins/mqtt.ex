defmodule Robotica.Plugins.MQTT do
  use GenServer
  use Robotica.Plugins.Plugin
  require Logger

  defmodule State do
    @type t :: %__MODULE__{}
    defstruct []
  end

  ## Server Callbacks

  def init(plugin) do
    {:ok, plugin}
  end

  def handle_call({:wait}, _from, state) do
    {:reply, nil, state}
  end

  def handle_cast({:execute, action}, state) do
    topic = "/action/#{state.location}/"
    client_id = Robotica.Supervisor.get_tortoise_client_id()

    with {:ok, action} <- Poison.encode(action),
         :ok <- Tortoise.publish(client_id, topic, action, qos: 0) do
      nil
    else
      {:error, _} -> Logger.debug("Cannot send outgoing action #{inspect(action)}")
    end

    {:noreply, state}
  end
end
