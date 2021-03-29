defmodule RoboticaFace.RoboticaService do
  @moduledoc false

  require Logger

  def process({:schedule = topic, id}) do
    steps = EventBus.fetch_event_data({topic, id})
    RoboticaFace.Schedule.set_schedule(steps)
    EventBus.mark_as_completed({__MODULE__, topic, id})
  end

  def process({:command_task = topic, id}) do
    task = EventBus.fetch_event_data({topic, id})
    RoboticaFace.Execute.command_task(task)
    EventBus.mark_as_completed({__MODULE__, topic, id})
  end
end
