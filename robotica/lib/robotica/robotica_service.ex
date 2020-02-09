defmodule Robotica.RoboticaService do
  @moduledoc false

  require Logger

  def process({:request_schedule = topic, id}) do
    Logger.info("got request_schedule")
    EventBus.fetch_event_data({topic, id})
    Robotica.Scheduler.Executor.request_schedule(Robotica.Scheduler.Executor)
    EventBus.mark_as_completed({__MODULE__, topic, id})
  end

  def process({:local_execute = topic, id}) do
    task = EventBus.fetch_event_data({topic, id})
    Logger.info("got local execute #{inspect(task)}")
    Robotica.Executor.execute(Robotica.Executor, task)
    EventBus.mark_as_completed({__MODULE__, topic, id})
  end

  def process({:remote_execute = topic, id}) do
    task = EventBus.fetch_event_data({topic, id})
    Logger.info("got remote execute #{inspect(task)}")
    Robotica.Mqtt.publish_execute(task)
    EventBus.mark_as_completed({__MODULE__, topic, id})
  end

  def process({:mark = topic, id}) do
    Logger.info("got mark")
    mark = EventBus.fetch_event_data({topic, id})
    #    Robotica.Scheduler.Marks.put_mark(Robotica.Scheduler.Marks, mark)
    #    Robotica.Scheduler.Executor.reload_marks(Robotica.Scheduler.Executor)
    Robotica.Mqtt.publish_mark(mark)
    EventBus.mark_as_completed({__MODULE__, topic, id})
  end
end
