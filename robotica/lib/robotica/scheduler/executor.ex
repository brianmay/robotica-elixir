defmodule Robotica.Scheduler.Executor do
  @moduledoc """
  Execute scheduled tasks
  """
  use GenServer
  use EventBus.EventSource

  require Logger

  alias Robotica.Scheduler.Classifier
  alias Robotica.Scheduler.Marks
  alias Robotica.Scheduler.Schedule
  alias Robotica.Scheduler.Sequence

  @timezone Application.compile_env(:robotica, :timezone)

  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def get_schedule(server) do
    GenServer.call(server, {:get_schedule})
  end

  def publish_schedule(server) do
    GenServer.cast(server, {:publish_schedule})
  end

  def request_schedule(server) do
    GenServer.cast(server, {:request_schedule})
  end

  @spec publish_steps(
          list(RoboticaCommon.ScheduledStep.t()),
          list(RoboticaCommon.ScheduledStep.t())
        ) :: nil

  defp publish_steps(steps, steps), do: nil

  defp publish_steps(_old_steps, steps) do
    :ok = RoboticaCommon.Mqtt.publish_schedule(steps)
  end

  @spec notify_steps(
          list(RoboticaCommon.ScheduledStep.t()),
          list(RoboticaCommon.ScheduledStep.t())
        ) :: nil

  defp notify_steps(steps, steps), do: nil

  defp notify_steps(_old_steps, steps) do
    EventSource.notify %{topic: :schedule} do
      steps
    end
  end

  def init(:ok) do
    today = DateTime.now!(@timezone) |> DateTime.to_date()
    yesterday = Date.add(today, -1)
    tomorrow = Date.add(today, 1)

    steps =
      []
      |> add_expanded_steps_for_date(yesterday)
      |> add_expanded_steps_for_date(today)
      |> add_expanded_steps_for_date(tomorrow)
      |> Sequence.sort_schedule()

    now = DateTime.utc_now()
    state = set_timer(now, {today, nil, steps})

    :ok =
      RoboticaCommon.Subscriptions.subscribe(
        ["mark"],
        :mark,
        self(),
        :json,
        :no_resend
      )

    {:ok, state}
  end

  defp maximum(v, max) when v > max, do: max
  defp maximum(v, _max), do: v
  defp minimum(v, min) when v < min, do: min
  defp minimum(v, _min), do: v

  defp set_timer(_now, {date, nil, []}) do
    timer = Process.send_after(self(), :timer, 60 * 1000)
    {date, timer, []}
  end

  defp set_timer(now, {date, nil, [step | tail] = list}) do
    required_time = step.required_time

    cond do
      DateTime.compare(now, required_time) == :lt ->
        updated_now = DateTime.utc_now()
        milliseconds = DateTime.diff(required_time, updated_now, :millisecond)
        # Ensure we wake up regularly so we can cope with system time changes.
        milliseconds = maximum(milliseconds, 60 * 1000)
        # Ensure we don't require time travel when sleeping negative times.
        milliseconds = minimum(milliseconds, 0)
        Logger.debug("Sleeping #{milliseconds} for #{inspect(step)}.")
        timer = Process.send_after(self(), :timer, milliseconds)
        {date, timer, list}

      true ->
        Logger.debug("Skipping #{inspect(step)}.")
        set_timer(now, {date, nil, tail})
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

  defp add_mark_to_step(%RoboticaCommon.ScheduledStep{} = step) do
    required_time = step.required_time
    mark = Marks.get_mark(Robotica.Scheduler.Marks, step.id)

    mark =
      cond do
        is_nil(mark) -> nil
        DateTime.compare(required_time, mark.start_time) == :lt -> nil
        DateTime.compare(required_time, mark.stop_time) in [:eq, :gt] -> nil
        true -> mark.status
      end

    %{step | mark: mark}
  end

  def add_marks_to_schedule(steps) do
    Enum.map(steps, fn step ->
      add_mark_to_step(step)
    end)
  end

  @spec execute_tasks(list(RoboticaCommon.Task.t())) :: :ok
  defp execute_tasks(tasks) do
    :ok = Robotica.Executor.execute_tasks(tasks)
  end

  defp do_step(%RoboticaCommon.ScheduledStep{id: id, mark: mark, tasks: tasks}) do
    cond do
      is_nil(mark) ->
        Logger.info("Executing step #{id}.")
        execute_tasks(tasks)

      mark == :done ->
        Logger.info("Skipping done step #{id}.")

      mark == :cancelled ->
        Logger.info("Skipping cancelled step #{id}.")

      true ->
        Logger.info("Executing marked task #{id}.")
        execute_tasks(tasks)
    end
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

  def handle_cast({:mqtt, _, :mark, json}, {date, timer, list} = state) do
    case Robotica.Config.validate_mark(json) do
      {:ok, mark} ->
        Marks.put_mark(Marks, mark)
        list = add_marks_to_schedule(list)
        notify_steps([], list)
        publish_steps([], list)
        new_state = {date, timer, list}
        {:noreply, new_state}

      {:error, reason} ->
        Logger.error("Invalid mark message received: #{inspect(reason)}.")
        {:noreply, state}
    end
  end

  def handle_info(:timer, {_, _, list} = state) do
    state = timer(list, state)
    {:noreply, state}
  end

  def timer(old_list, {date, _, [] = new_list}) do
    now = DateTime.utc_now()
    Logger.debug("Got timer at time #{inspect(now)} and no schedule.")
    finalize(now, date, old_list, new_list)
  end

  def timer(old_list, {date, timer, [step | tail] = new_list}) do
    now = DateTime.utc_now()
    Logger.debug("Got timer at time #{inspect(now)}.")

    {new_list, too_early} =
      cond do
        DateTime.compare(now, step.required_time) == :lt ->
          Logger.debug("Timer received too early for #{inspect(step)}.")
          {new_list, true}

        DateTime.compare(now, step.latest_time) == :lt ->
          Logger.debug("Timer received for #{inspect(step)}.")
          do_step(step)
          {tail, false}

        true ->
          Logger.debug("Timer received too late for #{inspect(step)}.")
          {tail, false}
      end

    # Keep processing list until we find a step that is still too early to run.
    case too_early do
      false -> timer(old_list, {date, timer, new_list})
      true -> finalize(now, date, old_list, new_list)
    end
  end

  defp finalize(now, date, old_list, new_list) do
    {date, new_list} = check_time_travel({date, new_list})
    state = set_timer(now, {date, nil, new_list})

    {_, _, new_list} = state
    notify_steps(old_list, new_list)
    publish_steps(old_list, new_list)

    state
  end

  defp check_time_travel({date, list}) do
    today = DateTime.now!(@timezone) |> DateTime.to_date()
    yesterday = Date.add(today, -1)
    tomorrow = Date.add(today, 1)

    new_list =
      cond do
        # If we have travelled back in time, we should drop the list entirely
        # to avoid duplicating future events.
        Date.compare(today, date) == :lt ->
          []
          |> add_expanded_steps_for_date(yesterday)
          |> add_expanded_steps_for_date(today)
          |> add_expanded_steps_for_date(tomorrow)
          |> add_marks_to_schedule()
          |> Sequence.sort_schedule()

        # If we have travelled forward in time by one day, we only need to
        # add events for tomorrow.
        Date.compare(yesterday, date) == :eq ->
          list
          |> add_expanded_steps_for_date(tomorrow)
          |> add_marks_to_schedule()
          |> Sequence.sort_schedule()

        # If we have travelled forward in time more then one day, regenerate
        # entire events list.
        Date.compare(today, date) == :gt ->
          []
          |> add_expanded_steps_for_date(yesterday)
          |> add_expanded_steps_for_date(today)
          |> add_expanded_steps_for_date(tomorrow)
          |> add_marks_to_schedule()
          |> Sequence.sort_schedule()

        # No change in date.
        true ->
          list
      end

    {today, new_list}
  end
end
