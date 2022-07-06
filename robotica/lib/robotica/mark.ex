defmodule Robotica.Mark do
  @moduledoc """
  Defines functions for marks
  """

  use RoboticaCommon.EventBus
  alias RoboticaCommon.Date

  @derive Jason.Encoder
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

  @spec publish_mark(Robotica.Mark.t()) :: :ok
  def publish_mark(%Robotica.Mark{} = mark) do
    RoboticaCommon.EventBus.notify(:mark, mark)
  end

  @spec mark_task(Robotica.Types.ScheduledStep.t(), :done | :cancelled | :clear) :: :error | :ok
  def mark_task(%Robotica.Types.ScheduledStep{} = step, status) do
    id = step.id
    now = DateTime.utc_now()
    prev_midnight = Date.today(step.required_time) |> Date.midnight_utc()
    next_midnight = Date.tomorrow(step.required_time) |> Date.midnight_utc()

    mark =
      case status do
        :done ->
          %Robotica.Mark{
            id: id,
            status: :done,
            start_time: prev_midnight,
            stop_time: next_midnight
          }

        :cancelled ->
          %Robotica.Mark{
            id: id,
            status: :cancelled,
            start_time: prev_midnight,
            stop_time: next_midnight
          }

        :clear ->
          %Robotica.Mark{
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
