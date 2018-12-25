defmodule Robotica.Scheduler.Executor do
  use GenServer
  use EventBus.EventSource

  require Logger

  alias Robotica.Types
  alias Robotica.Scheduler.Sequence
  alias Robotica.Scheduler.Classifier
  alias Robotica.Scheduler.Marks
  alias Robotica.Scheduler.Schedule

  @timezone Application.get_env(:robotica, :timezone)

  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def get_schedule(server) do
    GenServer.call(server, {:get_schedule})
  end

  def reload_marks(server) do
    GenServer.call(server, {:reload_marks})
  end

  def publish_schedule(server) do
    GenServer.cast(server, {:publish_schedule})
  end

  def request_schedule(server) do
    GenServer.cast(server, {:request_schedule})
  end

  @spec publish_steps(
          list(Types.MultiStep.t()),
          list(Types.MultiStep.t())
        ) :: nil

  defp publish_steps(steps, steps), do: nil

  defp publish_steps(_old_steps, steps) do
    case Robotica.Mqtt.publish_schedule(steps) do
      :ok -> nil
      {:error, _} -> Logger.debug("Cannot send current steps.")
    end
  end

  @spec notify_steps(
          list(Types.MultiStep.t()),
          list(Types.MultiStep.t())
        ) :: nil

  defp notify_steps(steps, steps), do: nil

  defp notify_steps(_old_steps, steps) do
    event_params = %{topic: :schedule}

    EventSource.notify event_params do
      steps
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

  defp add_mark_to_task(required_time, task) do
    mark = Marks.get_mark(Types.Marks, task.id)

    mark =
      cond do
        is_nil(mark) -> nil
        DateTime.compare(required_time, mark.expires_time) in [:gt, :eq] -> nil
        true -> mark.status
      end

    %{task | mark: mark}
  end

  def add_marks_to_schedule(list) do
    Enum.map(list, fn step ->
      tasks =
        Enum.map(step.tasks, fn task ->
          add_mark_to_task(step.required_time, task)
        end)

      %{step | tasks: tasks}
    end)
  end

  defp do_step(%Types.MultiStep{tasks: tasks}) do
    Enum.each(tasks, fn task ->
      cond do
        is_nil(task.mark) ->
          Logger.info("Executing #{inspect(task)}.")
          Robotica.Executor.execute(Robotica.Executor, task)

        task.mark == :done ->
          Logger.info("Skipping done task #{inspect(task)}.")

        task.mark == :cancelled ->
          Logger.info("Skipping cancelled task #{inspect(task)}.")

        true ->
          Logger.info("Executing marked task #{inspect(task)}.")
          Robotica.Executor.execute(Robotica.Executor, task)
      end
    end)

    nil
  end

  def handle_call({:get_schedule}, _from, {_, _, list} = state) do
    {:reply, list, state}
  end

  def handle_call({:reload_marks}, _from, {date, timer, list}) do
    list = add_marks_to_schedule(list)
    notify_steps([], list)
    publish_steps([], list)

    new_state = {date, timer, list}
    {:reply, nil, new_state}
  end

  def handle_cast({:publish_schedule}, {_, _, list} = state) do
    notify_steps([], list)
    publish_steps([], list)
    {:noreply, state}
  end

  def handle_cast({:request_schedule}, {_, _, list} = state) do
    notify_steps([], list)
    {:noreply, state}
  end

  def handle_info(:timer, {date, _, [] = list}) do
    now = Calendar.DateTime.now_utc()
    Logger.debug("Got dummy timer at time #{inspect(now)}.")
    {date, new_list} = check_time_travel({date, list})
    state = set_timer({date, nil, new_list})

    {_, _, new_list} = state
    notify_steps(list, new_list)
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
    notify_steps(list, new_list)
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
          |> add_marks_to_schedule()
          |> Sequence.squash_schedule()

        # If we have travelled forward in time by one day, we only need to
        # add events for tomorrow.
        Calendar.Date.same_date?(yesterday, date) ->
          list
          |> add_expanded_steps_for_date(tomorrow)
          |> add_marks_to_schedule()
          |> Sequence.squash_schedule()

        # If we have travelled forward in time more then one day, regenerate
        # entire events list.
        Calendar.Date.after?(today, date) ->
          []
          |> add_expanded_steps_for_date(yesterday)
          |> add_expanded_steps_for_date(today)
          |> add_expanded_steps_for_date(tomorrow)
          |> add_marks_to_schedule()
          |> Sequence.squash_schedule()

        # No change in date.
        true ->
          list
      end

    {today, new_list}
  end
end
