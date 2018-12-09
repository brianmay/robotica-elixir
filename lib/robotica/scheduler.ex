defmodule Robotica.Scheduler do
  require Logger

  defmodule Classification do
    @enforce_keys [:day_type]
    defstruct start: nil,
              stop: nil,
              date: nil,
              week_day: nil,
              day_of_week: nil,
              exclude: nil,
              day_type: nil
  end

  defmodule Step do
    @type t :: %__MODULE__{
            time: %DateTime{},
            zero_time: boolean(),
            task: Robotica.Executor.Task.t()
          }
    @enforce_keys [:time, :task]
    defstruct time: nil, zero_time: false, task: nil
  end

  defmodule ExpandedStep do
    @type t :: %__MODULE__{
            required_time: %DateTime{},
            latest_time: %DateTime{},
            tasks: list(Robotica.Executor.Task.t())
          }
    @enforce_keys [:required_time, :latest_time, :tasks]
    defstruct required_time: nil,
              latest_time: nil,
              tasks: []
  end

  defmodule Classifier do
    defp is_week_day?(date) do
      case Date.day_of_week(date) do
        dow when dow in 1..5 -> true
        _ -> false
      end
    end

    defmacrop classifications do
      data = Robotica.Config.classifications()
      Macro.escape(data)
    end

    defp is_date_in_classification?(%Classification{} = classification, date) do
      cond do
        not is_nil(classification.date) ->
          case Date.compare(date, classification.date) do
            :eq -> true
            _ -> false
          end

        true ->
          true
      end
    end

    defp is_date_range_in_classification?(%Classification{} = classification, date) do
      cond do
        not is_nil(classification.start) and not is_nil(classification.stop) ->
          case {Date.compare(date, classification.start), Date.compare(date, classification.stop)} do
            {a, b} when a in [:gt, :eq] and b in [:lt, :eq] ->
              true

            _ ->
              false
          end

        true ->
          true
      end
    end

    defp is_week_day_in_classification?(%Classification{} = classification, date) do
      cond do
        is_nil(classification.week_day) ->
          true

        classification.week_day == true ->
          is_week_day?(date)

        classification.week_day == false ->
          not is_week_day?(date)
      end
    end

    defp is_day_of_week_in_classification?(%Classification{} = classification, date) do
      cond do
        is_nil(classification.day_of_week) -> true
        classification.day_of_week == Date.day_of_week(date) -> true
        true -> false
      end
    end

    defp is_in_classification?(%Classification{} = classification, date) do
      with true <- is_date_in_classification?(classification, date),
           true <- is_date_range_in_classification?(classification, date),
           true <- is_week_day_in_classification?(classification, date),
           true <- is_day_of_week_in_classification?(classification, date) do
        true
      else
        false -> false
      end
    end

    defp is_excluded_entry?(classification_names, %Classification{} = classification) do
      exclude_list =
        if is_nil(classification.exclude) do
          []
        else
          classification.exclude
        end

      Enum.any?(exclude_list, fn exclude_name ->
        Enum.member?(classification_names, exclude_name)
      end)
    end

    defp reject_excluded(classifications) do
      classification_names =
        Enum.map(classifications, fn classification -> classification.day_type end)

      Enum.reject(classifications, fn classification ->
        is_excluded_entry?(classification_names, classification)
      end)
    end

    def classify_date(date) do
      classifications()
      |> Enum.filter(fn classification -> is_in_classification?(classification, date) end)
      |> reject_excluded()
      |> Enum.map(fn classification -> classification.day_type end)
    end
  end

  defmodule Schedule do
    @timezone Application.get_env(:robotica, :timezone)

    defmacrop schedule do
      data = Robotica.Config.schedule()
      Macro.escape(data)
    end

    defp convert_time_to_utc(date, time) do
      Calendar.DateTime.from_date_and_time_and_zone!(date, time, @timezone)
      |> Calendar.DateTime.shift_zone!("UTC")
    end

    defp add_schedule(date, scheduled, action, name) do
      action = Map.get(action, name, %{})

      action =
        action
        |> Enum.map(fn {k, v} -> {convert_time_to_utc(date, k), v} end)
        |> Enum.reduce(%{}, fn {k, vs}, acc ->
          Enum.reduce(vs, acc, fn v, acc -> Map.put(acc, v, k) end)
        end)

      Map.merge(scheduled, action)
    end

    def get_schedule(classifications, date) do
      a = schedule()

      schedule = add_schedule(date, %{}, a, "*")

      schedule =
        Enum.reduce(classifications, schedule, fn v, acc -> add_schedule(date, acc, a, v) end)
        |> Enum.reduce(%{}, fn {k, v}, acc ->
          Map.update(acc, v, MapSet.new([k]), &MapSet.put(&1, k))
        end)
        |> Map.to_list()
        |> Enum.sort(fn x, y -> Calendar.DateTime.before?(elem(x, 0), elem(y, 0)) end)

      schedule
    end
  end

  defmodule Sequence do
    defmacrop sequences do
      data = Robotica.Config.sequences()
      Macro.escape(data)
    end

    defp add_id_to_tasks([], _, _), do: []

    defp add_id_to_tasks([step | tail], sequence_name, n) do
        id = "#{sequence_name}_#{n}"
        step = %{step | task: %{step.task | id: id}}
        [step | add_id_to_tasks(tail, sequence_name, n+1)]
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
          time = Calendar.DateTime.subtract!(acc, step.time)
          {:cont, time}
        end
      end)
    end

    defp expand_steps(_, []), do: []

    defp expand_steps(start_time, [step | tail]) do
      required_time = start_time
      latest_time = Calendar.DateTime.add!(required_time, 300)

      expanded_step = %ExpandedStep{
        required_time: required_time,
        latest_time: latest_time,
        tasks: [step.task]
      }

      next_start_time = Calendar.DateTime.add!(start_time, step.time)
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

  defmodule Executor do
    use GenServer

    @timezone Application.get_env(:robotica, :timezone)

    def start_link(opts) do
      GenServer.start_link(__MODULE__, :ok, opts)
    end

    @spec publish_steps(
            list(Robotica.Scheduler.ExpandedStep.t()),
            list(Robotica.Scheduler.ExpandedStep.t())
          ) :: nil

    defp publish_steps(steps, steps), do: nil

    defp publish_steps(_old_steps, steps) do
      case Robotica.Mqtt.publish_schedule(steps) do
        :ok -> nil
        {:error, _} -> Logger.debug("Cannot send current steps.")
      end
    end

    def init(:ok) do
      today = Calendar.Date.today!(@timezone)
      yesterday = Calendar.Date.add!(today, -1)
      tomorrow = Calendar.Date.add!(today, 1)

      steps =
        []
        |> add_expanded_steps_for_date(yesterday)
        |> add_expanded_steps_for_date(today)
        |> add_expanded_steps_for_date(tomorrow)
        |> Sequence.squash_schedule()

      state = set_timer({today, nil, steps})
      {:ok, state}
    end

    def get_schedule(server) do
      GenServer.call(server, {:get_schedule})
    end

    def publish_schedule(server) do
      GenServer.cast(server, {:publish_schedule})
    end

    defp maximum(v, max) when v > max, do: max
    defp maximum(v, _max), do: v

    defp set_timer({date, nil, []}) do
      timer = Process.send_after(self(), :timer, 60 * 1000)
      {date, timer, []}
    end

    defp set_timer({date, nil, [step | tail] = list}) do
      required_time = step.required_time
      latest_time = step.latest_time

      now = Calendar.DateTime.now_utc()

      cond do
        Calendar.DateTime.before?(now, required_time) ->
          {:ok, s, ms, :after} = Calendar.DateTime.diff(required_time, now)
          milliseconds = Kernel.trunc(s * 1000 + ms / 1000)
          # Ensure we wake up regularly so we can cope with system time changes.
          milliseconds = maximum(milliseconds, 60 * 1000)
          Logger.debug("Sleeping #{milliseconds} for #{inspect(step)}.")
          timer = Process.send_after(self(), :timer, milliseconds)
          {date, timer, list}

        Calendar.DateTime.before?(now, latest_time) ->
          Logger.debug("Running late for #{inspect(step)}.")
          do_step(step)
          set_timer({date, nil, tail})

        true ->
          Logger.debug("Skipping #{inspect(step)}.")
          set_timer({date, nil, tail})
      end
    end

    def get_expanded_steps_for_date(date) do
      date
      |> Classifier.classify_date()
      |> Schedule.get_schedule(date)
      |> Sequence.expand_schedule()
    end

    def add_expanded_steps_for_date(list, date) do
      list ++ get_expanded_steps_for_date(date)
    end

    defp do_step(%ExpandedStep{tasks: tasks}) do
      Enum.each(tasks, fn task ->
        Logger.info("Executing #{inspect(task)}.")
        Robotica.Executor.execute(Robotica.Executor, task)
      end)

      nil
    end

    def handle_call({:get_schedule}, _from, {_, _, list} = state) do
      {:reply, list, state}
    end

    def handle_cast({:publish_schedule}, {_, _, list} = state) do
      publish_steps([], list)
      {:noreply, state}
    end

    def handle_info(:timer, {date, _, [] = list}) do
      now = Calendar.DateTime.now_utc()
      Logger.debug("Got dummy timer at time #{inspect(now)}.")
      {date, new_list} = check_time_travel({date, list})
      state = set_timer({date, nil, new_list})

      {_, _, new_list} = state
      publish_steps(list, new_list)

      {:noreply, state}
    end

    def handle_info(:timer, {date, _, [step | tail] = list}) do
      now = Calendar.DateTime.now_utc()
      Logger.debug("Got timer at time #{inspect(now)}.")

      new_list =
        cond do
          Calendar.DateTime.before?(now, step.required_time) ->
            Logger.debug("Timer received too early for #{inspect(step)}.")
            list

          Calendar.DateTime.before?(now, step.latest_time) ->
            Logger.debug("Timer received on time for #{inspect(step)}.")
            do_step(step)
            tail

          true ->
            Logger.debug("Timer received too late for #{inspect(step)}.")
            tail
        end

      {date, new_list} = check_time_travel({date, new_list})
      state = set_timer({date, nil, new_list})

      {_, _, new_list} = state
      publish_steps(list, new_list)

      {:noreply, state}
    end

    defp check_time_travel({date, list}) do
      today = Calendar.Date.today!(@timezone)
      yesterday = Calendar.Date.add!(today, -1)
      tomorrow = Calendar.Date.add!(today, 1)

      new_list =
        cond do
          # If we have travelled back in time, we should drop the list entirely
          # to avoid duplicating future events.
          Calendar.Date.before?(today, date) ->
            []
            |> add_expanded_steps_for_date(yesterday)
            |> add_expanded_steps_for_date(today)
            |> add_expanded_steps_for_date(tomorrow)
            |> Sequence.squash_schedule()

          # If we have travelled forward in time by one day, we only need to
          # add events for tomorrow.
          Calendar.Date.same_date?(yesterday, date) ->
            list
            |> add_expanded_steps_for_date(tomorrow)
            |> Sequence.squash_schedule()

          # If we have travelled forward in time more then one day, regenerate
          # entire events list.
          Calendar.Date.after?(today, date) ->
            []
            |> add_expanded_steps_for_date(yesterday)
            |> add_expanded_steps_for_date(today)
            |> add_expanded_steps_for_date(tomorrow)
            |> Sequence.squash_schedule()

          # No change in date.
          true ->
            list
        end

      {today, new_list}
    end
  end
end
