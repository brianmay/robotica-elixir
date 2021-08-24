defmodule Robotica.Plugins.Logging do
  use GenServer
  use Robotica.Plugin
  require Logger

  defmodule Config do
    @moduledoc false
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

  def handle_cast({:mqtt, _, :command, command}, state) do
    case check_type(command, "logging") do
      {command, true} ->
        publish(state.location, state.device, command)
        Logger.info(inspect(command))

      {_, false} ->
        state
    end

    {:noreply, state}
  end
end
