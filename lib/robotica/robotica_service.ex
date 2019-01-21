defmodule Robotica.RoboticaService do
  @moduledoc false

  require Logger

  def process({:request_schedule = topic, id}) do
    Logger.info("got request_schedule")
    EventBus.fetch_event_data({topic, id})
    Robotica.Scheduler.Executor.request_schedule(Robotica.Scheduler.Executor)
    EventBus.mark_as_completed({__MODULE__, topic, id})
  end

  def process({:execute = topic, id}) do
    Logger.info("got execute")
    task = EventBus.fetch_event_data({topic, id})
#    Robotica.Executor.execute(Robotica.Executor, task)
    Robotica.Mqtt.publish_execute(task)
    EventBus.mark_as_completed({__MODULE__, topic, id})
  end

  def process({:mark = topic, id}) do
    Logger.info("got mark")
    action = EventBus.fetch_event_data({topic, id})
    Robotica.Mqtt.publish_mark(action)
    EventBus.mark_as_completed({__MODULE__, topic, id})
  end
end
