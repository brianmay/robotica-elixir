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

    case Robotica.PluginRegistry.lookup_single(command.location, command.device) do
      nil ->
        Logger.info("got command #{inspect(command)} - remote")
        RoboticaPlugins.Mqtt.publish_command(command.location, command.device, command.msg)

      pid ->
        Logger.info("got command #{inspect(command)} - local")
        :ok = GenServer.cast(pid, {:mqtt, [], :command, command.msg})
    end

    EventBus.mark_as_completed({__MODULE__, topic, id})
  end

  def process({:mark = topic, id}) do
    mark = EventBus.fetch_event_data({topic, id})
    Logger.info("got mark #{inspect(mark)}")
    RoboticaPlugins.Mqtt.publish_mark(mark)
    EventBus.mark_as_completed({__MODULE__, topic, id})
  end

  def process({:subscribe = topic, id}) do
    data = EventBus.fetch_event_data({topic, id})
    RoboticaPlugins.Subscriptions.subscribe(data.topic, data.label, data.pid, data.format)
    EventBus.mark_as_completed({__MODULE__, topic, id})
  end

  def process({:unsubscribe_all = topic, id}) do
    data = EventBus.fetch_event_data({topic, id})
    RoboticaPlugins.Subscriptions.unsubscribe_all(data.pid)
    EventBus.mark_as_completed({__MODULE__, topic, id})
  end
end
