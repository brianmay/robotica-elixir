defmodule RoboticaFace.RoboticaService do
  @moduledoc false

  require Logger

  def process({:schedule = topic, id}) do
    steps = EventBus.fetch_event_data({topic, id})
    RoboticaFace.Schedule.set_schedule(steps)
    EventBus.mark_as_completed({__MODULE__, topic, id})
  end

  def process({:execute = topic, id}) do
    task = EventBus.fetch_event_data({topic, id})
    RoboticaFace.Execute.execute(task)
    EventBus.mark_as_completed({__MODULE__, topic, id})
  end

  def process({:tesla = topic, id}) do
    tesla_state = EventBus.fetch_event_data({topic, id})
    RoboticaFace.Tesla.update_tesla_state(tesla_state)
    EventBus.mark_as_completed({__MODULE__, topic, id})
  end
end
