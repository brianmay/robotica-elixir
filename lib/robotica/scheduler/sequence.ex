defmodule Robotica.Scheduler.Sequence do
  require Logger

  alias Robotica.Types

  defmacrop sequences do
    data = Robotica.Config.sequences()
    Macro.escape(data)
  end

  defp add_id_to_tasks([], _, _), do: []

  defp add_id_to_tasks([step | tail], sequence_name, n) do
    id = "#{sequence_name}_#{n}"
    step = %{step | task: %{step.task | id: id}}
    [step | add_id_to_tasks(tail, sequence_name, n + 1)]
  end

  defp get_sequence(sequence_name) do
    sequences()
    |> Map.fetch!(sequence_name)
    |> add_id_to_tasks(sequence_name, 0)
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

  defp expand_steps(_, []), do: []

  defp expand_steps(start_time, [step | tail]) do
    required_time = start_time

    latest_time =
      case step.latest_time do
        nil -> 300
        latest_time -> latest_time
      end

    latest_time = Calendar.DateTime.add!(required_time, latest_time)

    expanded_step = %Types.MultiStep{
      required_time: required_time,
      latest_time: latest_time,
      tasks: [step.task]
    }

    next_start_time = Calendar.DateTime.add!(start_time, step.required_time)
    [expanded_step] ++ expand_steps(next_start_time, tail)
  end

  defp expand_sequence(start_time, sequence_name) do
    Logger.debug("Loading sequence #{inspect(sequence_name)} for #{inspect(start_time)}.")
    sequence = get_sequence(sequence_name)
    start_time = get_corrected_start_time(start_time, sequence)

    Logger.debug(
      "Actual start time for sequence #{inspect(sequence_name)} is #{inspect(start_time)}."
    )

    expand_steps(start_time, sequence)
  end

  defp expand_sequences(start_time, sequence_names) do
    Enum.map(sequence_names, fn sequence_name ->
      expand_sequence(start_time, sequence_name)
    end)
  end

  def expand_schedule(schedule) do
    Enum.map(schedule, fn {start_time, sequence_names} ->
      expand_sequences(start_time, sequence_names)
    end)
    |> List.flatten()
  end

  def squash_schedule(schedule) do
    schedule
    |> Enum.sort(fn x, y -> Calendar.DateTime.before?(x.required_time, y.required_time) end)
    |> Enum.reduce([], fn v, acc ->
      case acc do
        [] ->
          [v]

        [head | tail] = list ->
          if head.required_time == v.required_time and head.latest_time == v.latest_time do
            head = Map.update!(head, :tasks, fn w -> w ++ v.tasks end)
            [head | tail]
          else
            [v | list]
          end
      end
    end)
    |> Enum.reverse()
  end
end
