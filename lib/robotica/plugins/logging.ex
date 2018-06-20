defmodule Robotica.Plugins.Logging do
  use GenServer
  use Robotica.Plugins.Plugin
  require Logger

  defmodule State do
    @type t :: %__MODULE__{}
    defstruct []
  end

  ## Server Callbacks

  def init(config) do
    {:ok, config}
  end

  def handle_call({:wait}, _from, state) do
    {:reply, nil, state}
  end

  def handle_cast({:execute, action}, state) do
    Logger.info(inspect(action))
    {:noreply, state}
  end
end
