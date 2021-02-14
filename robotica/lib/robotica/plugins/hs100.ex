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
            device: String.t(),
            last_seen: DateTime.t(),
            last_dead: boolean()
          }
    defstruct [:config, :location, :device, :last_seen, :last_dead]
  end

  ## Server Callbacks

  def init(plugin) do
    state = %State{
      config: plugin.config,
      location: plugin.location,
      device: plugin.device,
      last_seen: DateTime.utc_now(),
      last_dead: false
    }

    state =
      case TpLinkHs100.Client.get_device(state.config.id) do
        :error ->
          publish_device_hard_off(state)
          %State{state | last_dead: true}

        {:ok, device} ->
          device_state = if device.sysinfo["relay_state"] == 0, do: "OFF", else: "ON"
          publish_device_state(state, device_state)
          %State{state | last_dead: true}
      end

    {:ok, _} = :timer.send_interval(10_000, :refresh)

    TpLinkHs100.Client.add_handler(self())

    {:ok, state}
  end

  def config_schema do
    %{
      struct_type: Config,
      id: {:string, true}
    }
  end

  @spec publish_raw(State.t(), String.t(), String.t()) :: :ok
  defp publish_raw(%State{} = state, topic, value) do
    case RoboticaPlugins.Mqtt.publish_state_raw(state.location, state.device, value, topic: topic) do
      :ok ->
        :ok

      {:error, msg} ->
        Logger.error("Hs100 #{state.config.host}: publish_raw() got #{msg}")
    end

    :ok
  end

  @spec publish_device_state(State.t(), String.t()) :: :ok
  defp publish_device_state(%State{} = state, device_state) do
    publish_raw(state, "power", device_state)
  end

  @spec publish_device_error(State.t()) :: :ok
  defp publish_device_error(%State{} = state) do
    publish_raw(state, "power", "ERROR")
  end

  @spec publish_device_hard_off(State.t()) :: :ok
  defp publish_device_hard_off(%State{} = state) do
    publish_raw(state, "power", "HARD_OFF")
  end

  @spec handle_command(State.t(), map()) :: :ok
  def handle_command(%State{} = state, command) do
    {power, device_state} =
      case command.action do
        "turn_on" -> {true, "ON"}
        "turn_off" -> {false, "OFF"}
        _ -> {nil, nil}
      end

    if power != nil and device_state != nil do
      case TpLinkHs100.Client.get_device(state.config.id) do
        :error ->
          :ok

        {:ok, device} ->
          case TpLinkHs100.Device.switch(device, power) do
            :ok -> publish_device_state(state, device_state)
            {:error, _} -> publish_device_error(state)
          end
      end
    end
  end

  def handle_info(:refresh, %State{last_dead: false} = state) do
    duration = DateTime.diff(DateTime.utc_now(), state.last_seen)

    state =
      if duration >= 20 do
        publish_device_hard_off(state)
        %State{state | last_dead: true}
      else
        state
      end

    {:noreply, state}
  end

  def handle_info(:refresh, %State{last_dead: true} = state) do
    {:noreply, state}
  end

  def handle_cast({:mqtt, _, :command, command}, %State{} = state) do
    case Robotica.Config.validate_device_command(command) do
      {:ok, command} ->
        handle_command(state, command)

      {:error, error} ->
        Logger.error("Invalid hs100 command received: #{inspect(error)}.")
    end

    {:noreply, state}
  end

  def handle_cast({:added, %TpLinkHs100.Device{} = device}, %State{} = state) do
    state =
      if device.id == state.config.id do
        device_state = if device.sysinfo["relay_state"] == 0, do: "OFF", else: "ON"
        :ok = publish_device_state(state, device_state)
        %State{state | last_seen: DateTime.utc_now(), last_dead: false}
      else
        state
      end

    {:noreply, state}
  end

  def handle_cast({:updated, %TpLinkHs100.Device{} = device}, %State{} = state) do
    state =
      if device.id == state.config.id do
        device_state = if device.sysinfo["relay_state"] == 0, do: "OFF", else: "ON"
        :ok = publish_device_state(state, device_state)
        %State{state | last_seen: DateTime.utc_now(), last_dead: false}
      else
        state
      end

    {:noreply, state}
  end

  def handle_cast({:deleted, %TpLinkHs100.Device{} = device}, %State{} = state) do
    state =
      if device.id == state.config.id do
        :ok = publish_device_hard_off(state)
        %State{state | last_dead: true}
      else
        state
      end

    {:noreply, state}
  end

  def handle_cast({:execute, action}, %State{} = state) do
    case action.device do
      nil ->
        nil

      command ->
        handle_command(state, command)
    end

    {:noreply, state}
  end
end
