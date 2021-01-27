defmodule Robotica.Plugins.SonOff do
  use GenServer
  use Robotica.Plugin
  require Logger

  defmodule Config do
    @type t :: %__MODULE__{topic: String.t()}
    defstruct [:topic]
  end

  defmodule State do
    @type t :: %__MODULE__{
            config: Config.t(),
            location: String.t(),
            device: String.t()
          }
    defstruct [:config, :location, :device]
  end

  defp set_device_state(state, device_state) do
    Robotica.Mqtt.publish_state(state.location, state.device, device_state)
  end

  ## Server Callbacks

  def init(plugin) do
    Robotica.Subscriptions.subscribe(
      ["stat", plugin.config.topic, "RESULT"],
      :state,
      self()
    )

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
      topic: {:string, true}
    }
  end

  defp handle_command(state, command) do
    power =
      case command.action do
        "turn_on" -> "on"
        "turn_off" -> "off"
        _ -> nil
      end

    if power != nil do
      case Robotica.Mqtt.publish_raw("cmnd/#{state.config.topic}/power", power) do
        :ok -> nil
        {:error, _} -> Logger.debug("Cannot send sonoff action On.")
      end
    end
  end

  def handle_cast({:mqtt, _, :command, command}, state) do
    case Robotica.Config.validate_device_command(command) do
      {:ok, command} ->
        handle_command(state, command)

      {:error, error} ->
        Logger.error("Invalid sonoff command received: #{inspect(error)}.")
    end

    {:noreply, state}
  end

  def handle_cast({:mqtt, _, :state, msg}, state) do
    power = Map.fetch!(msg, "POWER")
    set_device_state(state, %{"POWER" => power})
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
