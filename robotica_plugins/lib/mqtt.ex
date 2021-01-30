defmodule RoboticaPlugins.Mqtt do

  @spec get_tortoise_client_id() :: String.t()
  def get_tortoise_client_id do
    {:ok, hostname} = :inet.gethostname()
    hostname = to_string(hostname)
    "robotica-#{hostname}"
  end

  @spec publish_raw(String.t(), String.t(), keyword()) :: :ok | {:error, String.t()}
  def publish_raw(topic, data, opts \\ []) do
    opts = Keyword.put_new(opts, :qos, 0)
    client_id = get_tortoise_client_id()
    Tortoise.publish(client_id, topic, data, opts)
  end

  @spec publish_json(String.t(), list() | map(), keyword()) :: :ok | {:error, String.t()}
  def publish_json(topic, data, opts \\ []) do
    with {:ok, data} <- Poison.encode(data),
         :ok <- publish_raw(topic, data, opts) do
      :ok
    else
      {:error, msg} -> {:error, "Tortoise.publish got error '#{msg}'"}
    end
  end

  @spec publish_action(String.t(), RoboticaPlugins.Action.t()) :: :ok | {:error, String.t()}
  def publish_action(location, action) do
    topic = "action/#{location}"
    publish_json(topic, action)
  end

  @spec publish_state(String.t(), String.t(), map(), keyword()) :: :ok | {:error, String.t()}
  def publish_state(location, device, state, opts \\ []) do
    {topic, opts} = Keyword.pop(opts, :topic)
    opts = Keyword.put(opts, :retain, true)

    topic =
      if topic == nil do
        "state/#{location}/#{device}"
      else
        "state/#{location}/#{device}/#{topic}"
      end

    publish_json(topic, state, opts)
  end

  @spec publish_schedule(list(RoboticaPlugins.ScheduledStep.t())) :: :ok | {:error, String.t()}
  def publish_schedule(steps) do
    client_id = get_tortoise_client_id()
    topic = "schedule/#{client_id}"
    publish_json(topic, steps, retain: true)
  end

  @spec publish_mark(map()) :: :ok | {:error, String.t()}
  def publish_mark(action) do
    topic = "mark"

    action = %{
      action
      | start_time: DateTime.to_iso8601(action.start_time),
        stop_time: DateTime.to_iso8601(action.stop_time)
    }

    publish_json(topic, action)
  end

  @spec publish_execute(RoboticaPlugins.Task.t()) :: :ok | {:error, String.t()}
  def publish_execute(task) do
    topic = "execute"
    publish_json(topic, task)
  end

  @spec publish_command(String.t(), String.t(), map()) :: :ok | {:error, String.t()}
  def publish_command(location, device, msg) do
    topic =  "command/#{location}/#{device}"
    publish_json(topic, msg)
  end
end