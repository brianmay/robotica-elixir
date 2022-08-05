defmodule Robotica.Executor do
  @moduledoc """
  Execute Robotica tasks in a pseudo synchronised manner
  """

  require Logger

  use RoboticaCommon.EventBus
  use EventBus.EventSource

  alias Robotica.Types.CommandTask
  alias Robotica.Types.Task

  @spec execute_tasks(tasks :: list(Task.t())) :: :ok
  def execute_tasks(tasks) do
    Enum.each(tasks, fn scheduled_task ->
      Enum.each(scheduled_task.topics, fn topic ->
        qos = scheduled_task.qos || 1

        command = %CommandTask{
          topic: topic,
          payload_str: scheduled_task.payload_str,
          payload_json: scheduled_task.payload_json,
          qos: qos
        }

        Robotica.Mqtt.publish_command_task(command)
      end)
    end)
  end
end
