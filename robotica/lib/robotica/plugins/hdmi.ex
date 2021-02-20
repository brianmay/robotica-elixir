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
    {:ok, _timer} = :timer.send_interval(60_000, :poll)
    Process.send_after(self(), :poll, 0)
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
  defp publish_device_output(%Robotica.Plugin{} = state, input, output) do
    topic = "output#{output}"
    publish_raw(state, topic, Integer.to_string(input))
  end

  @spec publish_device_output_off(Robotica.Plugin.t(), integer) :: :ok
  defp publish_device_output_off(%Robotica.Plugin{} = state, output) do
    topic = "output#{output}"
    publish_raw(state, topic, "OFF")
  end

  @spec publish_device_output_hard_off(Robotica.Plugin.t(), integer) :: :ok
  defp publish_device_output_hard_off(%Robotica.Plugin{} = state, output) do
    topic = "output#{output}"
    publish_raw(state, topic, "HARD_OFF")
  end

  @spec poll(Robotica.Plugin.t(), list(integer)) :: :ok | {:error, String.t()}
  defp poll(%Robotica.Plugin{}, []), do: :ok

  defp poll(%Robotica.Plugin{} = state, [output | tail]) do
    case Robotica.Devices.HDMI.get_input_for_output(state.config.host, output) do
      {:ok, input} ->
        publish_device_output(state, input, output)
        poll(state, tail)

      {:error, error} ->
        Logger.error("HDMI #{state.config.host}: error: #{error}")
        {:error, error}
    end
  end

  def handle_info(:poll, %Robotica.Plugin{} = state) do
    outputs = [1, 2, 3, 4]

    case poll(state, outputs) do
      :ok ->
        :ok

      {:error, _error} ->
        Enum.each(outputs, fn remaining_output ->
          publish_device_output_hard_off(state, remaining_output)
        end)
    end

    {:noreply, state}
  end

  def handle_info({:mojito_response, nil, {:error, :closed}}, %Robotica.Plugin{} = state) do
    outputs = [1, 2, 3, 4]

    Logger.error("HDMI #{state.config.host}: Got connection closed.")
    Enum.each(outputs, fn remaining_output ->
      publish_device_output_hard_off(state, remaining_output)
    end)
  end

def handle_info({_, :ok}, %Robotica.Plugin{} = state) do
  Logger.error("HDMI #{state.config.host}: Got unhandled OK message.")
end

  def handle_command(%Robotica.Plugin{} = state, command) do
    Logger.info("HDMI #{state.config.host}: #{command.input} #{command.output}")

    publish_device_output_off(state, command.output)

    case Robotica.Devices.HDMI.switch(state.config.host, command.input, command.output) do
      :ok ->
        publish_device_output(state, command.input, command.output)

      {:error, error} ->
        Logger.error("HDMI #{state.config.host}: error: #{error}")
        publish_device_output_hard_off(state, command.output)
    end

    {:noreply, state}
  end

  def handle_cast({:mqtt, _, :command, command}, %Robotica.Plugin{} = state) do
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

  def handle_cast({:execute, action}, %Robotica.Plugin{} = state) do
    case action.hdmi do
      nil ->
        nil

      command ->
        handle_command(state, command)
    end

    {:noreply, state}
  end
end
