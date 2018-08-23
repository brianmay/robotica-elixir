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
    Logger.info(inspect(action))
    Logger.info(inspect(state))
    topic = "execute/#{state.location}"

    with {:ok, action} <- Poison.encode(action) do
      Tortoise.publish(Tortoise.Connection, topic, action, qos: 0)
    else
      {:error, err} -> {:error, err}
    end

    {:noreply, state}
  end
end
