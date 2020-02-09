defmodule RoboticaPlugins.Mark do
  alias RoboticaPlugins.Date
  use EventBus.EventSource

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

  @spec publish_mark(t()) :: :ok | {:error, String.t()}
  def publish_mark(mark) do
    EventSource.notify %{topic: :mark} do
      mark
    end
  end

  def mark_task(step, status) do
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
        :ok
    end
  end
end
