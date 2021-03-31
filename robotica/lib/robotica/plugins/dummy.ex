defmodule Robotica.Plugins.Dummy do
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

  @spec publish_device_state(Robotica.Plugin.t(), String.t()) :: :ok
  defp publish_device_state(state, device_state) do
    case RoboticaPlugins.Mqtt.publish_state_raw(state.location, state.device, device_state,
           topic: "power"
         ) do
      :ok -> :ok
      {:error, msg} -> Logger.error("publish_device_state() got #{msg}")
    end
  end

  def handle_command(state, command) do
    device_state =
      case command.action do
        "turn_on" -> "ON"
        "turn_off" -> "OFF"
        _ -> nil
      end

    if device_state != nil do
      publish_device_state(state, device_state)
    end
  end

  def handle_cast({:mqtt, _, :command, command}, state) do
    case Robotica.Config.validate_device_command(command) do
      {:ok, command} ->
        if command.type == "device" or command.type == nil do
          handle_command(state, command)
        else
          Logger.info("Wrong type #{command.type}, expected device")
        end

      {:error, error} ->
        Logger.error("Invalid dummy command received: #{inspect(error)}.")
    end

    {:noreply, state}
  end
end
