defmodule Robotica.Plugins.Hs100 do
  @moduledoc """
  hs100 switch plugin
  """

  use GenServer
  use Robotica.Plugin
  require Logger

  defmodule Config do
    @moduledoc false
    @type t :: %__MODULE__{id: String.t()}
    defstruct [:id]
  end

  defmodule State do
    @moduledoc false
    @type t :: %__MODULE__{
            config: Config.t(),
            location: String.t(),
            device: String.t()
          }
    defstruct [:config, :location, :device]
  end

  ## Server Callbacks

  def init(plugin) do
    state = %State{
      config: plugin.config,
      location: plugin.location,
      device: plugin.device
    }

    case TpLinkHs100.Client.get_device(state.config.id) do
      :error ->
        publish_device_hard_off(state)

      {:ok, device} ->
        device_state = if device.sysinfo["relay_state"] == 0, do: "OFF", else: "ON"
        publish_device_state(state, device_state)
    end

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
    :ok = Robotica.Mqtt.publish_state_raw(state.location, state.device, value, topic: topic)
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
    publish(state.location, state.device, command)

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

  def handle_cast({:mqtt, _, :command, command}, %State{} = state) do
    case Robotica.Config.validate_device_command(command) do
      {:ok, command} ->
        if command.type == "device" or command.type == nil do
          handle_command(state, command)
        else
          Logger.info("Wrong type #{command.type}, expected device")
          state
        end

      {:error, error} ->
        Logger.error("Invalid hs100 command received: #{inspect(error)}.")
    end

    {:noreply, state}
  end

  def handle_cast({:added, %TpLinkHs100.Device{} = device}, %State{} = state) do
    if device.id == state.config.id do
      device_state = if device.sysinfo["relay_state"] == 0, do: "OFF", else: "ON"
      :ok = publish_device_state(state, device_state)
    end

    {:noreply, state}
  end

  def handle_cast({:updated, %TpLinkHs100.Device{} = device}, %State{} = state) do
    if device.id == state.config.id do
      device_state = if device.sysinfo["relay_state"] == 0, do: "OFF", else: "ON"
      :ok = publish_device_state(state, device_state)
    end

    {:noreply, state}
  end

  def handle_cast({:deleted, %TpLinkHs100.Device{} = device}, %State{} = state) do
    if device.id == state.config.id do
      :ok = publish_device_hard_off(state)
    end

    {:noreply, state}
  end
end
