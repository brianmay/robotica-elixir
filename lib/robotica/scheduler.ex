defmodule Robotica.Scheduler do
  require Logger

  @timezone Application.get_env(:robotica, :timezone)

  defmodule Classification do
    @enforce_keys [:day_type]
    defstruct start: nil, stop: nil, date: nil, week_day: nil, day_of_week: nil, day_type: nil
  end

  defmodule Step do
    @enforce_keys [:time, :locations, :actions]
    defstruct time: nil, zero_time: false, locations: nil, actions: nil, load_schedule: nil
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

    def classify_date(date) do
      classifications()
      |> Enum.filter(fn classification -> is_in_classification?(classification, date) end)
      |> Enum.map(fn classification -> classification.day_type end)
    end
  end

  defmodule Schedule do
    @timezone Application.get_env(:robotica, :timezone)

    defmacrop schedule do
      data = Robotica.Config.schedule()
      Macro.escape(data)
    end

    defp convert_time_to_utc(time) do
      today = Calendar.Date.today!(@timezone)

      Calendar.DateTime.from_date_and_time_and_zone!(today, time, @timezone)
      |> Calendar.DateTime.shift_zone!("UTC")
    end

    defp add_schedule(scheduled, actions, name) do
      action = Map.fetch!(actions, name)

      action =
        action
        |> Enum.map(fn {k, v} -> {convert_time_to_utc(k), v} end)
        |> Enum.reduce(%{}, fn {k, vs}, acc ->
          Enum.reduce(vs, acc, fn v, acc -> Map.put(acc, v, k) end)
        end)

      Map.merge(scheduled, action)
    end

    def get_schedule(classifications) do
      a = schedule()

      tomorrow = Calendar.Date.today!(@timezone) |> Calendar.Date.next_day!()

      midnight =
        tomorrow
        |> Calendar.DateTime.from_date_and_time_and_zone!(~T[00:00:00], @timezone)
        |> Calendar.DateTime.shift_zone!("UTC")

      schedule =
        %{"reschedule" => midnight}
        |> add_schedule(a, "*")

      schedule =
        Enum.reduce(classifications, schedule, fn v, acc -> add_schedule(acc, a, v) end)
        |> Enum.reduce(%{}, fn {k, v}, acc ->
          Map.update(acc, v, MapSet.new([k]), &MapSet.put(&1, k))
        end)
        |> Map.to_list()
        |> Enum.sort(fn x, y -> Calendar.DateTime.before?(elem(x, 0), elem(y, 0)) end)

      schedule
    end
  end

  defmodule Sequencer do
    use GenServer, restart: :transient

    def start_link(state) do
      GenServer.start_link(__MODULE__, state)
    end

    def init(state) do
      state = set_timer(state)

      case state do
        {_, []} -> {:stop, :normal}
        _ -> {:ok, state}
      end
    end

    defp set_timer({_, []} = state), do: state

    defp set_timer({start_time, [step | tail]} = state) do
      seconds = step.time
      required_time = Calendar.DateTime.add!(start_time, seconds)
      latest_time = Calendar.DateTime.add!(required_time, 300)

      now = Calendar.DateTime.now_utc()

      cond do
        Calendar.DateTime.before?(now, required_time) ->
          {:ok, s, ms, :after} = Calendar.DateTime.diff(required_time, now)
          milliseconds = Kernel.trunc(s * 1000 + ms / 1000)
          Logger.debug("Sleeping #{inspect(milliseconds)} until #{inspect(required_time)}.")
          Process.send_after(self(), {:timer, required_time, latest_time}, milliseconds)
          state

        Calendar.DateTime.before?(now, latest_time) ->
          Logger.debug("Running late for #{inspect(required_time)}.")
          do_step(required_time, step)
          set_timer({required_time, tail})

        true ->
          Logger.debug("Skipping #{inspect(required_time)}.")
          set_timer({required_time, tail})
      end
    end

    defp do_step(_required_time, %Step{locations: locations, actions: actions} = step) do
      Logger.debug("Executing #{inspect(actions)} at locations #{inspect(locations)}")
      Robotica.Executor.execute(Robotica.Executor, locations, actions)

      if step.load_schedule do
        Robotica.Scheduler.load_schedule()
      end

      nil
    end

    def handle_info({:timer, required_time, latest_time}, {_, [step | tail]}) do
      now = Calendar.DateTime.now_utc()
      Logger.debug("Got timer at time #{inspect(now)}")

      if Calendar.DateTime.before?(now, latest_time) do
        do_step(required_time, step)
      else
        Logger.debug("Timer received too late for #{inspect(step)} @ #{inspect(required_time)}")
      end

      state = set_timer({required_time, tail})

      case state do
        {_, []} -> {:stop, :normal, state}
        _ -> {:noreply, state}
      end
    end
  end

  defmodule Sequence do
    defmacrop sequences do
      data = Robotica.Config.sequences()
      Macro.escape(data)
    end

    defp get_sequence(sequence_name) do
      sequences()
      |> Map.fetch!(sequence_name)
    end

    defp get_start_time(required_time, sequence) do
      Enum.reduce_while(sequence, required_time, fn step, acc ->
        time = Calendar.DateTime.subtract!(acc, step.time)

        if step.zero_time do
          {:halt, time}
        else
          {:cont, time}
        end
      end)
    end

    def execute_schedule([]), do: nil

    def execute_schedule([head | tail]) do
      {required_time, sequence_names} = head

      Enum.each(sequence_names, fn sequence_name ->
        Logger.debug("")
        Logger.debug("Loading schedule #{inspect(sequence_name)} for #{inspect(required_time)}.")
        sequence = get_sequence(sequence_name)
        required_time = get_start_time(required_time, sequence)
        Logger.debug("Actual start time for #{inspect(sequence_name)} is #{inspect(required_time)}.")
        state = {required_time, sequence}
        r = DynamicSupervisor.start_child(:dynamic, {Sequencer, state})

        case r do
          {:ok, _pid} -> nil
          {:error, :normal} -> nil
          r -> Logger.debug("Error #{inspect(r)}.")
        end
      end)

      execute_schedule(tail)
    end
  end

  def load_schedule do
    Calendar.Date.today!(@timezone)
    |> Classifier.classify_date()
    |> Schedule.get_schedule()
    |> Sequence.execute_schedule()
  end
end
