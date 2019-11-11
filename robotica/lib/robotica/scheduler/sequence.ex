defmodule Robotica.Scheduler.Sequence do
  require Logger

  @filename Application.get_env(:robotica, :sequences_file)
  @external_resource @filename
  @data Robotica.Config.sequences(@filename)

  defp add_id_to_tasks([], _, _), do: []

  defp add_id_to_tasks([step | tail], sequence_name, n) do
    id = "#{sequence_name}_#{n}"
    step = %{step | task: %{step.task | id: id}}
    [step | add_id_to_tasks(tail, sequence_name, n + 1)]
  end

  defp get_sequence(sequence_name) do
    @data
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

    expanded_step = %RoboticaPlugins.MultiStep{
      required_time: required_time,
      latest_time: latest_time,
      tasks: [step.task]
    }

    next_start_time = Calendar.DateTime.add!(start_time, step.required_time)
    [expanded_step] ++ expand_steps(next_start_time, tail)
  end

  defp repeat_task([step | _] = step_list, %RoboticaPlugins.ScheduledTask{} = task) do
    cond do
      task.repeat_count <= 0 ->
        step_list

      is_nil(task.repeat_time) ->
        step_list

      true ->
        new_task = %RoboticaPlugins.ScheduledTask{task | repeat_count: task.repeat_count - 1}

        new_step = %RoboticaPlugins.MultiStep{
          step
          | required_time: Calendar.DateTime.add!(step.required_time, task.repeat_time),
            latest_time: Calendar.DateTime.add!(step.latest_time, task.repeat_time),
            tasks: [new_task]
        }

        new_step_list = [new_step | step_list]
        repeat_task(new_step_list, new_task)
    end
  end

  defp expand_sequence(start_time, sequence_name) do
    Logger.debug("Loading sequence #{inspect(sequence_name)} for #{inspect(start_time)}.")
    sequence = get_sequence(sequence_name)
    start_time = get_corrected_start_time(start_time, sequence)

    Logger.debug(
      "Actual start time for sequence #{inspect(sequence_name)} is #{inspect(start_time)}."
    )

    expand_steps(start_time, sequence)
    |> Enum.map(fn step -> repeat_task([step], hd(step.tasks)) end)
    |> List.flatten()
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
