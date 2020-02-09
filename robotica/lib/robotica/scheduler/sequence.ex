defmodule Robotica.Scheduler.Sequence do
  require Logger

  @filename Application.get_env(:robotica, :sequences_file)
  @external_resource @filename
  @data Robotica.Config.sequences(@filename)

  defp add_id_to_steps([], _, _), do: []

  defp add_id_to_steps([step | tail], sequence_name, n) do
    id = "#{sequence_name}_#{n}"
    step = %{step | id: id}
    [step | add_id_to_steps(tail, sequence_name, n + 1)]
  end

  defp get_sequence(sequence_name) do
    Map.fetch!(@data, sequence_name)
    |> add_id_to_steps(sequence_name, 0)
  end

  defp get_corrected_start_time(start_time, sequence) do
    Enum.reduce_while(sequence, start_time, fn step, acc ->
      if step.zero_time do
        {:halt, acc}
      else
        time = Calendar.DateTime.subtract!(acc, step.required_time)
        {:cont, time}
      end
    end)
  end

  defp schedule_steps([], _), do: []

  defp schedule_steps([step | tail], start_time) do
    required_time = start_time

    latest_time =
      case step.latest_time do
        nil -> 300
        latest_time -> latest_time
      end

    latest_time = Calendar.DateTime.add!(required_time, latest_time)

    scheduled_step = %RoboticaPlugins.ScheduledStep{
      required_time: required_time,
      latest_time: latest_time,
      tasks: step.tasks,
      id: step.id,
      repeat_number: step.repeat_number
    }

    next_start_time = Calendar.DateTime.add!(start_time, step.required_time)
    [scheduled_step | schedule_steps(tail, next_start_time)]
  end

  defp repeat_step(step) do
    cond do
      step.repeat_count <= 0 ->
        step

      is_nil(step.repeat_time) ->
        step

      true ->
        required_time = step.required_time
        repeat_time = step.repeat_time * (step.repeat_count + 1)

        extra_time =
          if repeat_time >= required_time do
            0
          else
            required_time - repeat_time
          end

        list = [{step.repeat_count+1, step.repeat_time + extra_time}]

        list =
          step.repeat_count..1
          |> Enum.reduce(list, fn i, acc ->
            [{i, step.repeat_time} | acc]
          end)

        Enum.map(list, fn {i, required_time} ->
          %RoboticaPlugins.SourceStep{
            step
            | required_time: required_time,
              repeat_number: i
          }
        end)
    end
  end

  defp expand_sequence(start_time, sequence_name) do
    Logger.debug("Loading sequence #{inspect(sequence_name)} for #{inspect(start_time)}.")
    sequence = get_sequence(sequence_name)
    start_time = get_corrected_start_time(start_time, sequence)

    Logger.debug(
      "Actual start time for sequence #{inspect(sequence_name)} is #{inspect(start_time)}."
    )

    sequence
    |> Enum.map(fn step -> repeat_step(step) end)
    |> List.flatten()
    |> schedule_steps(start_time)
  end

  defp expand_sequences(start_time, sequence_names) do
    Enum.map(sequence_names, fn sequence_name ->
      expand_sequence(start_time, sequence_name)
    end)
    |> List.flatten()
  end

  def expand_schedule(schedule) do
    Enum.map(schedule, fn {start_time, sequence_names} ->
      expand_sequences(start_time, sequence_names)
    end)
    |> List.flatten()
  end

  def sort_schedule(scheduled_steps) do
    scheduled_steps
    |> Enum.sort(fn x, y -> Calendar.DateTime.before?(x.required_time, y.required_time) end)
  end
end
