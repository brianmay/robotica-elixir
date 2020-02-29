defmodule Robotica.Plugins.Hs100 do
  use GenServer
  use Robotica.Plugin
  require Logger

  defmodule Config do
    @type t :: %__MODULE__{id: String.t()}
    defstruct [:id]
  end

  ## Server Callbacks

  def init(plugin) do
    {:ok, plugin}
  end

  def config_schema do
    %{
      struct_type: Config,
      id: {:string, true}
    }
  end

  def handle_cast({:execute, action}, state) do
    case action.device do
      nil ->
        nil

      device ->
        case device.action do
          "turn_on" -> TpLinkHs100.on(state.config.id)
          "turn_off" -> TpLinkHs100.off(state.config.id)
          "toggle" -> :ok
          _ -> :ok
        end
    end

    {:noreply, state}
  end
end
