defmodule RoboticaPlugins.Mark do
  use RoboticaPlugins.EventBus
  alias RoboticaPlugins.Date

  @type t :: %__MODULE__{
          id: String.t(),
          status: :done | :cancelled,
          start_time: %DateTime{},
          stop_time: %DateTime{}
        }
  @enforce_keys [:id, :status, :start_time, :stop_time]
  defstruct id: nil,
            status: nil,
            start_time: nil,
            stop_time: nil

  @spec publish_mark(RoboticaPlugins.Mark.t()) :: :ok
  def publish_mark(%RoboticaPlugins.Mark{} = mark) do
    RoboticaPlugins.EventBus.notify(:mark, mark)
  end

  @spec mark_task(RoboticaPlugins.ScheduledStep.t(), :done | :cancelled | :clear) :: :error | :ok
  def mark_task(%RoboticaPlugins.ScheduledStep{} = step, status) do
    id = step.id
    now = DateTime.utc_now()
    prev_midnight = Date.today(step.required_time) |> Date.midnight_utc()
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

        :cancelled ->
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
    end
  end
end
