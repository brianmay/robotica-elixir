defmodule Robotica.Plugins.HDMI do
  use GenServer
  use Robotica.Plugin
  require Logger

  defmodule Config do
    @type t :: %__MODULE__{}
    defstruct [:host, :destination]
  end

  ## Server Callbacks

  def init(plugin) do
    {:ok, plugin}
  end

  def config_schema do
    %{
      struct_type: Config,
      host: {:string, true},
      destination: {:integer, true}
    }
  end

  @spec publish_device_state(Robotica.Plugin.t(), String.t()) :: :ok
  defp publish_device_state(state, device_state) do
    case RoboticaPlugins.Mqtt.publish_state_raw(state.location, state.device, device_state) do
      :ok -> :ok
      {:error, msg} -> Logger.error("publish_device_state() got #{msg}")
    end
  end

  def handle_command(state, command) do
    Logger.info("HDMI #{state.config.host} #{command.source} #{state.config.destination}")

    case Robotica.Devices.HDMI.switch(state.config.host, command.source, state.config.destination) do
      :ok ->
        publish_device_state(state, Integer.to_string(command.source))

      {:error, error} ->
        Logger.error("HDMI error: #{error}")
        publish_device_state(state, "ERROR")
    end

    {:noreply, state}
  end

  def handle_cast({:mqtt, _, :command, command}, state) do
    case Robotica.Config.validate_hdmi_command(command) do
      {:ok, command} -> handle_command(state, command)
      {:error, error} -> Logger.error("Invalid hdmi command received: #{inspect(error)}.")
    end

    {:noreply, state}
  end

  def handle_cast({:execute, action}, state) do
    case action.hdmi do
      nil ->
        nil

      command ->
        handle_command(state, command)
    end

    {:noreply, state}
  end
end
