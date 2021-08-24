defmodule Robotica.Plugins.SonOff do
  @moduledoc """
  Sonoff plugin
  """
  use GenServer
  use Robotica.Plugin
  require Logger

  defmodule Config do
    @moduledoc false
    @type t :: %__MODULE__{topic: String.t()}
    defstruct [:topic]
  end

  defmodule State do
    @moduledoc false
    @type t :: %__MODULE__{
            config: Config.t(),
            location: String.t(),
            device: String.t(),
            last_power: String.t() | nil
          }
    defstruct [:config, :location, :device, :last_power]
  end

  @spec publish_device_state(State.t(), String.t()) :: :ok
  defp publish_device_state(%State{} = state, device_state) do
    publish_state_raw(state, "power", device_state)
  end

  # @spec publish_device_error(State.t()) :: :ok
  # defp publish_device_error(%State{} = state) do
  #   publish_state_raw(state, "power", "ERROR")
  # end

  @spec publish_device_hard_off(State.t()) :: :ok
  defp publish_device_hard_off(%State{} = state) do
    publish_state_raw(state, "power", "HARD_OFF")
  end

  @spec publish_device_unknown(State.t()) :: :ok
  defp publish_device_unknown(%State{} = state) do
    publish_state_raw(state, "power", "")
  end

  ## Server Callbacks

  def init(plugin) do
    Robotica.Subscriptions.subscribe(
      ["stat", plugin.config.topic, "POWER"],
      :power,
      self(),
      :raw,
      :resend
    )

    Robotica.Subscriptions.subscribe(
      ["tele", plugin.config.topic, "LWT"],
      :lwt,
      self(),
      :raw,
      :resend
    )

    {:ok,
     %State{
       config: plugin.config,
       location: plugin.location,
       device: plugin.device,
       last_power: nil
     }}
  end

  def config_schema do
    %{
      struct_type: Config,
      topic: {:string, true}
    }
  end

  defp handle_command(state, command) do
    publish_command(state.location, state.device, command)

    power =
      case command.action do
        "turn_on" -> "ON"
        "turn_off" -> "OFF"
        _ -> nil
      end

    if power != nil do
      :ok = Robotica.Mqtt.publish_raw("cmnd/#{state.config.topic}/power", power)
    else
      :ok
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
        Logger.error("Invalid sonoff command received: #{inspect(error)}.")
    end

    {:noreply, state}
  end

  def handle_cast({:mqtt, _, :power, power}, state) do
    publish_device_state(state, power)
    state = %State{state | last_power: power}
    {:noreply, state}
  end

  def handle_cast({:mqtt, _, :lwt, msg}, state) do
    cond do
      msg != "Online" -> publish_device_hard_off(state)
      state.last_power != nil -> publish_device_state(state, state.last_power)
      true -> publish_device_unknown(state)
    end

    {:noreply, state}
  end
end
