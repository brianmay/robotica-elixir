defmodule Robotica.RoboticaService do
  @moduledoc false

  require Logger

  def process({:request_schedule = topic, id}) do
    Logger.info("got request_schedule")
    EventBus.fetch_event_data({topic, id})
    Robotica.Scheduler.Executor.request_schedule(Robotica.Scheduler.Executor)
    EventBus.mark_as_completed({__MODULE__, topic, id})
  end

  def process({:command = topic, id}) do
    command = EventBus.fetch_event_data({topic, id})
    Logger.info("got remote execute #{inspect(command)}")
    Enum.each(command.locations, fn location ->
        Enum.each(command.devices, fn device ->
            RoboticaPlugins.Mqtt.publish_command(location, device, command.msg)
        end)
    end)
    EventBus.mark_as_completed({__MODULE__, topic, id})
  end

  def process({:mark = topic, id}) do
    Logger.info("got mark")
    mark = EventBus.fetch_event_data({topic, id})
    #    Robotica.Scheduler.Marks.put_mark(Robotica.Scheduler.Marks, mark)
    #    Robotica.Scheduler.Executor.reload_marks(Robotica.Scheduler.Executor)
    RoboticaPlugins.Mqtt.publish_mark(mark)
    EventBus.mark_as_completed({__MODULE__, topic, id})
  end
end
