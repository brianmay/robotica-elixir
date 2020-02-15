defmodule Robotica.Mqtt do
  @spec publish_raw(String.t(), String.t()) :: :ok | {:error, String.t()}
  def publish_raw(topic, data) do
    client_id = Robotica.Supervisor.get_tortoise_client_id()
    Tortoise.publish(client_id, topic, data, qos: 0)
  end

  @spec publish_json(String.t(), list() | map()) :: :ok | {:error, String.t()}
  def publish_json(topic, data) do
    with {:ok, data} <- Poison.encode(data),
         :ok <- publish_raw(topic, data) do
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

  @spec publish_schedule(list(RoboticaPlugins.ScheduledStep.t())) :: :ok | {:error, String.t()}
  def publish_schedule(steps) do
    client_id = Robotica.Supervisor.get_tortoise_client_id()
    topic = "schedule/#{client_id}"
    publish_json(topic, steps)
  end

  @spec publish_mark(map()) :: :ok | {:error, String.t()}
  def publish_mark(action) do
    topic = "mark"

    action = %{
      action
      | start_time: Calendar.DateTime.Format.iso8601(action.start_time),
        stop_time: Calendar.DateTime.Format.iso8601(action.stop_time)
    }

    publish_json(topic, action)
  end

  @spec publish_execute(Robotica.Executor.Task.t()) :: :ok | {:error, String.t()}
  def publish_execute(task) do
    topic = "execute"
    publish_json(topic, task)
  end
end
