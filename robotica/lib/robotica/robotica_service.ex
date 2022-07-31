defmodule Robotica.RoboticaService do
  @moduledoc false

  require Logger

  def process({:command = topic, id}) do
    task = EventBus.fetch_event_data({topic, id})
    Logger.info("got command #{inspect(task.topic)}")
    Robotica.Mqtt.publish_command_task(task)
    EventBus.mark_as_completed({__MODULE__, topic, id})
  end

  def process({:mark = topic, id}) do
    mark = EventBus.fetch_event_data({topic, id})
    Logger.info("got mark #{inspect(mark)}")
    Robotica.Mqtt.publish_mark(mark)
    EventBus.mark_as_completed({__MODULE__, topic, id})
  end

  def process({:subscribe = topic, id}) do
    data = EventBus.fetch_event_data({topic, id})

    MqttPotion.Multiplexer.subscribe_str(
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
    MqttPotion.Multiplexer.unsubscribe_all(data.pid)
    EventBus.mark_as_completed({__MODULE__, topic, id})
  end
end
