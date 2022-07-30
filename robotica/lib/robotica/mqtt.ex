defmodule Robotica.Mqtt do
  @moduledoc """
  Common MQTT functions
  """
  use GenServer

  require Logger

  alias Robotica.Types.CommandTask
  alias Robotica.Types.ScheduledStep

  @spec get_tortoise_client_id() :: String.t()
  def get_tortoise_client_id do
    {:ok, hostname} = :inet.gethostname()
    hostname = to_string(hostname)
    "robotica-#{hostname}"
  end

  @spec get_tortoise_client_name() :: atom()
  def get_tortoise_client_name do
    Robotica.MqttPotion
  end

  @spec publish_raw(String.t(), String.t(), MqttPotion.pub_opts()) :: :ok
  def publish_raw(topic, data, opts \\ []) do
    opts = Keyword.put_new(opts, :qos, 0)
    client_name = get_tortoise_client_name()

    :ok = MqttPotion.Multiplexer.message(topic, data)
    :ok = MqttPotion.publish(client_name, topic, data, opts)
  end

  @spec publish_json(String.t(), list() | map(), MqttPotion.pub_opts()) :: :ok
  def publish_json(topic, data, opts \\ []) do
    case Jason.encode(data) do
      {:ok, data} -> publish_raw(topic, data, opts)
      {:error, msg} -> Logger.error("Jason.encode() got error '#{msg}'")
    end
  end

  @spec get_state_topic(String.t(), String.t(), String.t() | nil) :: String.t()
  defp get_state_topic(location, device, nil) do
    "state/#{location}/#{device}"
  end

  defp get_state_topic(location, device, topic) do
    "state/#{location}/#{device}/#{topic}"
  end

  @spec publish_state_raw(String.t(), String.t(), String.t(), keyword()) :: :ok
  def publish_state_raw(location, device, state, opts \\ []) do
    {topic, opts} = Keyword.pop(opts, :topic)
    opts = Keyword.put_new(opts, :retain, true)
    topic = get_state_topic(location, device, topic)
    GenServer.cast(__MODULE__, {:send_state, topic, state, opts})
  end

  @spec publish_state_json(String.t(), String.t(), list() | map(), keyword()) :: :ok
  def publish_state_json(location, device, state, opts \\ []) do
    case Jason.encode(state) do
      {:ok, state} -> publish_state_raw(location, device, state, opts)
      {:error, msg} -> Logger.error("Jason.encode() got error '#{msg}'")
    end
  end

  @spec publish_schedule(list(ScheduledStep.t())) :: :ok
  def publish_schedule(steps) do
    host = Robotica.CommonConfig.hostname()
    topic = "schedule/#{host}"
    publish_json(topic, steps, retain: true)
  end

  @spec publish_mark(map()) :: :ok
  def publish_mark(action) do
    topic = "mark"

    action = %{
      action
      | start_time: DateTime.to_iso8601(action.start_time),
        stop_time: DateTime.to_iso8601(action.stop_time)
    }

    publish_json(topic, action)
  end

  @spec publish_command_task(command :: CommandTask.t()) :: :ok
  def publish_command_task(%CommandTask{} = command) do
    Logger.info("sending command task #{command.topic}")

    case command do
      %{payload_str: payload_str} when payload_str != nil ->
        :ok = publish_raw(command.topic, payload_str)

      %{payload_json: payload_json} when payload_json != nil ->
        :ok = publish_json(command.topic, command.payload_json)

      _ ->
        :ok = publish_raw(command.topic, "")
    end

    :ok
  end

  @spec start_link(opts :: list) :: {:ok, pid} | {:error, String.t()}
  def start_link(opts) do
    {:ok, _pid} = GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_) do
    {:ok, %{}}
  end

  @impl true
  def handle_cast({:send_state, topic, new_value, opts}, state) do
    changed =
      case Map.fetch(state, topic) do
        {:ok, old_value} -> old_value != new_value
        :error -> true
      end

    if changed do
      publish_raw(topic, new_value, opts)
    end

    state = Map.put(state, topic, new_value)
    {:noreply, state}
  end
end
