defmodule RoboticaUi.RoboticaService do
  @moduledoc false

  def process({:schedule = topic, id}) do
    steps = EventBus.fetch_event_data({topic, id})
    RoboticaUi.Schedule.set_schedule(steps)
    EventBus.mark_as_completed({__MODULE__, topic, id})
  end

  def process({:execute = topic, id}) do
    action = EventBus.fetch_event_data({topic, id})
    RoboticaUi.Execute.execute(action)
    EventBus.mark_as_completed({__MODULE__, topic, id})
  end
end
