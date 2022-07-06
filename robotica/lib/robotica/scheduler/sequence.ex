defmodule Robotica.Scheduler.Sequence do
  @moduledoc """
  Load and process a schedule sequence
  """
  require Logger

  alias Robotica.Config.Loader
  alias Robotica.Scheduler.Schedule.Schedule

  if Application.compile_env(:robotica_common, :compile_config_files) do
    @filename Application.compile_env(:robotica, :sequences_file)
    @external_resource @filename
    @data Loader.sequences(@filename)
    defp get_data, do: @data
  else
    defp get_data do
      filename = Application.get_env(:robotica, :sequences_file)
      Loader.sequences(filename)
    end
  end

  defp add_id_to_steps([], _, _), do: []

  defp add_id_to_steps([step | tail], sequence_name, n) do
    id = "#{sequence_name}_#{n}"
    step = %{step | id: id}
    [step | add_id_to_steps(tail, sequence_name, n + 1)]
  end

  defp is_condition_ok?(step, options, classifications_today, classifications_tomorrow) do
    condition_list = Map.get(step, :if)

    if condition_list == nil do
      true
    else
      values = %{
        "options" => options,
        "today" => classifications_today.classifications,
        "tomorrow" => classifications_tomorrow.classifications
      }

      Enum.any?(condition_list, fn condition ->
        {:ok, result} = RoboticaCommon.Strings.eval_string_to_bool(condition, values)

        result
      end)
    end
  end

  defp is_classifications_ok?(step, c_today) do
    case step.classifications do
      nil ->
        true

      step_classifications ->
        Enum.any?(step_classifications, fn step_classification ->
          MapSet.member?(c_today.classifications, step_classification)
        end)
    end
  end

  defp is_options_ok?(step, options) do
    case step.options do
      nil ->
        true

      step_options ->
        Enum.any?(step_options, fn step_option ->
          MapSet.member?(options, step_option)
        end)
    end
  end

  defp get_sequence(sequence_name, c_today, c_tomorrow, options) do
    Map.fetch!(get_data(), sequence_name)
    |> add_id_to_steps(sequence_name, 0)
    |> Enum.filter(fn step ->
      is_condition_ok?(step, options, c_today, c_tomorrow) and
        is_classifications_ok?(step, c_today) and
        is_options_ok?(step, options)
    end)
  end

  defp get_corrected_start_time(start_time, sequence) do
    Enum.reduce_while(sequence, start_time, fn step, acc ->
      if step.zero_time do
        {:halt, acc}
      else
        time = DateTime.add(acc, -step.required_time, :second)
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

    latest_time = DateTime.add(required_time, latest_time, :second)

    scheduled_step = %RoboticaCommon.ScheduledStep{
      required_time: required_time,
      latest_time: latest_time,
      tasks: step.tasks,
      id: step.id,
      repeat_number: step.repeat_number
    }

    next_start_time = DateTime.add(start_time, step.required_time, :second)
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

        list = [{step.repeat_count + 1, step.repeat_time + extra_time}]

        list =
          step.repeat_count..1
          |> Enum.reduce(list, fn i, acc ->
            [{i, step.repeat_time} | acc]
          end)

        Enum.map(list, fn {i, required_time} ->
          %RoboticaCommon.SourceStep{
            step
            | required_time: required_time,
              repeat_number: i
          }
        end)
    end
  end

  defp expand_sequence(start_time, {sequence_name, options}, c_today, c_tomorrow) do
    Logger.debug("Loading sequence #{inspect(sequence_name)} for #{inspect(start_time)}.")
    sequence = get_sequence(sequence_name, c_today, c_tomorrow, options)
    start_time = get_corrected_start_time(start_time, sequence)

    Logger.debug(
      "Actual start time for sequence #{inspect(sequence_name)} is #{inspect(start_time)}."
    )

    sequence
    |> Enum.map(fn step -> repeat_step(step) end)
    |> List.flatten()
    |> schedule_steps(start_time)
  end

  defp expand_sequences(start_time, sequence_details, c_today, c_tomorrow) do
    Enum.map(sequence_details, fn sequence_detail ->
      expand_sequence(start_time, sequence_detail, c_today, c_tomorrow)
    end)
    |> List.flatten()
  end

  @spec expand_schedule(Schedule.t()) :: list(any())
  def expand_schedule(schedule) do
    Enum.map(schedule.schedule, fn {start_time, sequence_details} ->
      expand_sequences(
        start_time,
        sequence_details,
        schedule.today,
        schedule.tomorrow
      )
    end)
    |> List.flatten()
  end

  def sort_schedule(scheduled_steps) do
    scheduled_steps
    |> Enum.sort(fn x, y -> DateTime.compare(x.required_time, y.required_time) == :lt end)
  end
end
