defmodule Robotica.Plugins.Dummy do
  @moduledoc """
  Dummy switch plugin
  """

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
    {:ok, plugin}
  end

  def config_schema do
    %{
      struct_type: Config
    }
  end

  @spec publish_device_state(Robotica.Plugin.t(), String.t()) :: :ok
  defp publish_device_state(state, device_state) do
    :ok =
      Robotica.Mqtt.publish_state_raw(state.location, state.device, device_state, topic: "power")
  end

  def handle_command(state, command) do
    publish(state.location, state.device, command)

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
        case check_type(command, "device") do
          {command, true} -> handle_command(state, command)
          {_, false} -> state
        end

      {:error, error} ->
        Logger.error("Invalid dummy command received: #{inspect(error)}.")
    end

    {:noreply, state}
  end
end
