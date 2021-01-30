defmodule Ceryx.CeryxService do
  @moduledoc false

  require Logger

  def process({:request_schedule = topic, id}) do
    Logger.info("got request_schedule")
    EventBus.fetch_event_data({topic, id})
    EventBus.mark_as_completed({__MODULE__, topic, id})
  end

  def process({:command = topic, id}) do
    Logger.info("got command #{inspect(command)}")
    Enum.each(command.locations, fn location ->
        Enum.each(command.devices, fn device ->
            Ceryx.Mqtt.publish_command(location, device, command.msg)
        end)
    end)
    EventBus.mark_as_completed({__MODULE__, topic, id})
  end

  def process({:mark = topic, id}) do
    Logger.info("got mark")
    mark = EventBus.fetch_event_data({topic, id})
    Ceryx.Mqtt.publish_mark(mark)
    EventBus.mark_as_completed({__MODULE__, topic, id})
  end
end
