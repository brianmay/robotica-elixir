defmodule Ceryx.CeryxService do
  @moduledoc false

  require Logger

  def process({:request_schedule = topic, id}) do
    Logger.info("got request_schedule")
    EventBus.fetch_event_data({topic, id})
    Ceryx.Mqtt.request_schedule()
    EventBus.mark_as_completed({__MODULE__, topic, id})
  end

  def process({:local_execute = topic, id}) do
    task = EventBus.fetch_event_data({topic, id})
    Logger.info("got local execute #{inspect(task)}")
    Ceryx.Mqtt.publish_execute(task)
    EventBus.mark_as_completed({__MODULE__, topic, id})
  end

  def process({:remote_execute = topic, id}) do
    task = EventBus.fetch_event_data({topic, id})
    Logger.info("got remote execute #{inspect(task)}")
    Ceryx.Mqtt.publish_execute(task)
    EventBus.mark_as_completed({__MODULE__, topic, id})
  end

  def process({:mark = topic, id}) do
    Logger.info("got mark")
    mark = EventBus.fetch_event_data({topic, id})
    Ceryx.Mqtt.publish_mark(mark)
    EventBus.mark_as_completed({__MODULE__, topic, id})
  end
end
