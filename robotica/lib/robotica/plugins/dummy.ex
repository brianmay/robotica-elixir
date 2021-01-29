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

  defp set_device_state(state, device_state) do
    Robotica.Mqtt.publish_state(state.location, state.device, device_state)
  end

  def handle_command(state, command) do
    device_state =
      case command.action do
        "turn_on" -> %{"POWER" => "ON"}
        "turn_off" -> %{"POWER" => "OFF"}
        _ -> nil
      end

    if device_state != nil do
      set_device_state(state, device_state)
    end
  end

  def handle_cast({:mqtt, _, :command, command}, state) do
    case Robotica.Config.validate_device_command(command) do
      {:ok, command} ->
        handle_command(state, command)

      {:error, error} ->
        Logger.error("Invalid dummy command received: #{inspect(error)}.")
    end

    {:noreply, state}
  end

  def handle_cast({:execute, action}, state) do
    case action.device do
      nil ->
        nil

      command ->
        handle_command(state, command)
    end

    {:noreply, state}
  end
end
