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

  def handle_command(state, command) do
    device_state =
      case command.action do
        "turn_on" ->
          TpLinkHs100.on(state.config.id)
          %{"state" => "on"}

        "turn_off" ->
          TpLinkHs100.off(state.config.id)
          %{"state" => "off"}

        _ ->
          nil
      end

    if device_state != nil do
      Robotica.Mqtt.publish_state(state.location, state.device, device_state)
    end
  end

  def handle_cast({:command, command}, state) do
    case Robotica.Config.validate_device_command(command) do
      {:ok, command} -> handle_command(state, command)
      {:error, error} -> Logger.error("Invalid hs100 command received: #{inspect(error)}.")
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
