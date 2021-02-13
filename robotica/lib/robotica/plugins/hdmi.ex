defmodule Robotica.Plugins.HDMI do
  use GenServer
  use Robotica.Plugin
  require Logger

  alias Robotica.Plugin

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
      host: {:string, true}
    }
  end

  @spec publish_raw(Plugin.t(), String.t(), String.t()) :: :ok
  defp publish_raw(%Plugin{} = state, topic, value) do
    case RoboticaPlugins.Mqtt.publish_state_raw(state.location, state.device, value, topic: topic) do
      :ok ->
        :ok

      {:error, msg} ->
        Logger.error("HDMI #{state.config.host}: publish_raw() got #{msg}")
    end

    :ok
  end

  @spec publish_device_output(Robotica.Plugin.t(), integer, integer) :: :ok
  defp publish_device_output(state, input, output) do
    topic = "output#{output}"
    publish_raw(state, topic, Integer.to_string(input))
  end

  @spec publish_device_output_off(Robotica.Plugin.t(), integer) :: :ok
  defp publish_device_output_off(state, output) do
    topic = "output#{output}"
    publish_raw(state, topic, "OFF")
  end

  @spec publish_device_output_error(Robotica.Plugin.t(), integer) :: :ok
  defp publish_device_output_error(state, output) do
    topic = "output#{output}"
    publish_raw(state, topic, "ERROR")
  end

  def handle_command(state, command) do
    Logger.info("HDMI #{state.config.host}: #{command.input} #{command.output}")

    publish_device_output_off(state, command.output)

    case Robotica.Devices.HDMI.switch(state.config.host, command.input, command.output) do
      :ok ->
        publish_device_output(state, command.input, command.output)

      {:error, error} ->
        Logger.error("HDMI #{state.config.host}: error: #{error}")
        publish_device_output_error(state, command.output)
    end

    {:noreply, state}
  end

  def handle_cast({:mqtt, _, :command, command}, state) do
    case Robotica.Config.validate_hdmi_command(command) do
      {:ok, command} ->
        handle_command(state, command)

      {:error, error} ->
        Logger.error(
          "HDMI #{state.config.host}: Invalid hdmi command received: #{inspect(error)}."
        )
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
