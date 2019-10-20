defmodule RoboticaFace.Mark do
  alias RoboticaFace.Date
  use EventBus.EventSource

  @spec publish_mark(RoboticaPlugin.Mark.t()) :: :ok | {:error, String.t()}
  def publish_mark(mark) do
    EventSource.notify %{topic: :mark} do
      mark
    end
  end

  def mark_task(step, status) do
    id = step.task.id
    now = Calendar.DateTime.now_utc()
    prev_midnight = Date.midnight_utc(step.required_time)
    next_midnight = Date.tomorrow(step.required_time) |> Date.midnight_utc()

    mark =
      case status do
        :done ->
          %RoboticaPlugins.Mark{
            id: id,
            status: :done,
            start_time: prev_midnight,
            stop_time: next_midnight
          }

        :postponed ->
          %RoboticaPlugins.Mark{
            id: id,
            status: :cancelled,
            start_time: prev_midnight,
            stop_time: next_midnight
          }

        :clear ->
          %RoboticaPlugins.Mark{
            id: id,
            status: :done,
            start_time: now,
            stop_time: now
          }

        _ ->
          nil
      end

    case mark do
      nil ->
        :error

      _ ->
        publish_mark(mark)
        :ok
    end
  end
end
