defmodule Robotica.Mqtt do
  @spec publish(String.t(), list() | map()) :: :ok | {:error, String.t()}
  defp publish(topic, data) do
    client_id = Robotica.Supervisor.get_tortoise_client_id()

    with {:ok, data} <- Poison.encode(data),
         :ok <- Tortoise.publish(client_id, topic, data, qos: 0) do
      :ok
    else
      {:error, msg} -> {:error, "Tortoise.publish got error '#{msg}'"}
    end
  end

  @spec publish_action(String.t(), RoboticaPlugins.Action.t()) :: :ok | {:error, String.t()}
  def publish_action(location, action) do
    topic = "action/#{location}"
    publish(topic, action)
  end

  @spec publish_schedule(list(RoboticaPlugins.MultiStep.t())) :: :ok | {:error, String.t()}
  def publish_schedule(steps) do
    client_id = Robotica.Supervisor.get_tortoise_client_id()
    topic = "schedule/#{client_id}"
    publish(topic, steps)
  end

  @spec publish_mark(map()) :: :ok | {:error, String.t()}
  def publish_mark(action) do
    topic = "mark"

    action = %{
      action
      | start_time: Calendar.DateTime.Format.iso8601(action.start_time),
        stop_time: Calendar.DateTime.Format.iso8601(action.stop_time)
    }

    publish(topic, action)
  end

  @spec publish_execute(Robotica.Executor.Task.t()) :: :ok | {:error, String.t()}
  def publish_execute(task) do
    topic = "execute"
    publish(topic, task)
  end
end
