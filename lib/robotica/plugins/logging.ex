defmodule Robotica.Plugins.Logging do
  use GenServer
  use RoboticaPlugins.Plugin
  require Logger

  defmodule Config do
    @type t :: %__MODULE__{}
    defstruct []
  end

  ## Server Callbacks

  def init(plugin) do
    {:ok, plugin.config}
  end

  def config_schema do
    %{
      struct_type: Config
    }
  end

  def handle_cast({:execute, action}, state) do
    Logger.info(inspect(action))
    {:noreply, state}
  end
end
