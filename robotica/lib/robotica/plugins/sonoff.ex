defmodule Robotica.Plugins.SonOff do
  use GenServer
  use Robotica.Plugin
  require Logger

  defmodule Config do
    @type t :: %__MODULE__{topic: String.t()}
    defstruct [:topic]
  end

  ## Server Callbacks

  def init(plugin) do
    {:ok, plugin}
  end

  def config_schema do
    %{
      struct_type: Config,
      topic: {:string, true}
    }
  end

  def handle_cast({:execute, action}, state) do
    case action.device do
      nil ->
        nil

      device ->
        power =
          case device.action do
            "turn_on" -> "on"
            "turn_off" -> "off"
            "toggle" -> "toggle"
            _ -> "off"
          end

        case Robotica.Mqtt.publish_raw("cmnd/#{state.config.topic}/power", power) do
          :ok -> nil
          {:error, _} -> Logger.debug("Cannot send sonoff action On.")
        end
    end

    {:noreply, state}
  end
end
