defmodule Robotica.RoboticaService do
  @moduledoc false

  require Logger

  def process({:request_schedule = topic, id}) do
    Logger.info("got request_schedule")
    EventBus.fetch_event_data({topic, id})
    Robotica.Scheduler.Executor.request_schedule(Robotica.Scheduler.Executor)
    EventBus.mark_as_completed({__MODULE__, topic, id})
  end
end
