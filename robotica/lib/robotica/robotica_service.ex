defmodule Robotica.RoboticaService do
  @moduledoc false

  require Logger

  alias Robotica.Scheduler.Executor

  def process({:request_schedule = topic, id}) do
    Logger.info("got request_schedule")
    EventBus.fetch_event_data({topic, id})
    Executor.request_schedule(Executor)
    EventBus.mark_as_completed({__MODULE__, topic, id})
  end

  def process({:command = topic, id}) do
    task = EventBus.fetch_event_data({topic, id})
    Robotica.PluginRegistry.execute_command_task(task, remote: true)
    EventBus.mark_as_completed({__MODULE__, topic, id})
  end

  def process({:mark = topic, id}) do
    mark = EventBus.fetch_event_data({topic, id})
    Logger.info("got mark #{inspect(mark)}")
    RoboticaCommon.Mqtt.publish_mark(mark)
    EventBus.mark_as_completed({__MODULE__, topic, id})
  end

  def process({:subscribe = topic, id}) do
    data = EventBus.fetch_event_data({topic, id})

    RoboticaCommon.Subscriptions.subscribe(
      data.topic,
      data.label,
      data.pid,
      data.format,
      data.resend
    )

    EventBus.mark_as_completed({__MODULE__, topic, id})
  end

  def process({:unsubscribe_all = topic, id}) do
    data = EventBus.fetch_event_data({topic, id})
    RoboticaCommon.Subscriptions.unsubscribe_all(data.pid)
    EventBus.mark_as_completed({__MODULE__, topic, id})
  end
end
