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

  defp set_device_state(state, device_state) do
    RoboticaPlugins.Mqtt.publish_state(state.location, state.device, device_state)
  end

  def handle_command(state, command) do
    device_state =
      case command.action do
        "turn_on" ->
          TpLinkHs100.on(state.config.id)
          %{"POWER" => "ON"}

        "turn_off" ->
          TpLinkHs100.off(state.config.id)
          %{"POWER" => "OFF"}

        _ ->
          nil
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
