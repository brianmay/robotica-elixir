defmodule Robotica.Plugins.Hs100 do
  use GenServer
  use Robotica.Plugin
  require Logger

  defmodule Config do
    @type t :: %__MODULE__{id: String.t()}
    defstruct [:id]
  end

  defmodule State do
    @type t :: %__MODULE__{
            config: Config.t(),
            location: String.t(),
            device: String.t()
          }
    defstruct [:config, :location, :device]
  end

  ## Server Callbacks

  def init(plugin) do
    {:ok,
     %State{
       config: plugin.config,
       location: plugin.location,
       device: plugin.device
     }}
  end

  def config_schema do
    %{
      struct_type: Config,
      id: {:string, true}
    }
  end

  @spec publish_device_state(State.t(), String.t()) :: :ok
  defp publish_device_state(state, device_state) do
    case RoboticaPlugins.Mqtt.publish_state_raw(state.location, state.device, device_state) do
      :ok -> :ok
      {:error, msg} -> Logger.error("set_device_state() got #{msg}")
    end
  end

  def handle_command(state, command) do
    device_state =
      case command.action do
        "turn_on" ->
          TpLinkHs100.on(state.config.id)
          "ON"

        "turn_off" ->
          TpLinkHs100.off(state.config.id)
          "OFF"

        _ ->
          nil
      end

    if device_state != nil do
      publish_device_state(state, device_state)
    end
  end

  def handle_cast({:mqtt, _, :command, command}, state) do
    case Robotica.Config.validate_device_command(command) do
      {:ok, command} ->
        handle_command(state, command)

      {:error, error} ->
        Logger.error("Invalid hs100 command received: #{inspect(error)}.")
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
