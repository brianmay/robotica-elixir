defmodule Robotica.Mqtt do
  @moduledoc """
  Common MQTT functions
  """
  require Logger

  @spec get_tortoise_client_id() :: String.t()
  def get_tortoise_client_id do
    {:ok, hostname} = :inet.gethostname()
    hostname = to_string(hostname)
    "robotica-#{hostname}"
  end

  @spec get_tortoise_client_name() :: atom()
  def get_tortoise_client_name do
    __MODULE__
  end

  @spec publish_raw(String.t(), String.t(), MqttPotion.pub_opts()) :: :ok
  def publish_raw(topic, data, opts \\ []) do
    opts = Keyword.put_new(opts, :qos, 0)
    client_name = get_tortoise_client_name()

    :ok = MqttPotion.publish(client_name, topic, data, opts)
  end

  @spec publish_json(String.t(), list() | map(), MqttPotion.pub_opts()) :: :ok
  def publish_json(topic, data, opts \\ []) do
    case Poison.encode(data) do
      {:ok, data} -> publish_raw(topic, data, opts)
      {:error, msg} -> Logger.error("Poison.encode() got error '#{msg}'")
    end
  end

  @spec publish_command_task(RoboticaCommon.CommandTask.t()) :: :ok
  def publish_command_task(%RoboticaCommon.CommandTask{} = task) do
    topic = "action/#{task.location}/#{task.device}"
    publish_json(topic, task.command)
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
    publish_raw(topic, state, opts)
  end

  @spec publish_state_json(String.t(), String.t(), list() | map(), keyword()) :: :ok
  def publish_state_json(location, device, state, opts \\ []) do
    {topic, opts} = Keyword.pop(opts, :topic)
    opts = Keyword.put_new(opts, :retain, true)
    topic = get_state_topic(location, device, topic)
    publish_json(topic, state, opts)
  end

  @spec publish_schedule(list(RoboticaCommon.ScheduledStep.t())) :: :ok
  def publish_schedule(steps) do
    client_id = get_tortoise_client_id()
    topic = "schedule/#{client_id}"
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

  @spec publish_execute(RoboticaCommon.Task.t()) :: :ok
  def publish_execute(task) do
    topic = "execute"
    publish_json(topic, task)
  end

  @spec publish_command(String.t(), String.t(), map()) :: :ok
  def publish_command(location, device, msg) do
    topic = "command/#{location}/#{device}"
    publish_json(topic, msg)
  end
end
