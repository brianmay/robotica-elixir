defmodule Robotica.Scheduler.Sequence.Test do
  use ExUnit.Case, async: true

  import Robotica.Scheduler.Sequence

  def local_datetime(dt) do
    {:ok, dt} = Calendar.DateTime.from_naive(dt, "Australia/Melbourne")
    Calendar.DateTime.shift_zone!(dt, "UTC")
  end

  def assert_datetime(dt1, dt2) do
    assert DateTime.compare(dt1, dt2) == :eq, "#{dt1} != #{dt2}"
  end

  def assert_tasks(tasks, message) do
    task = hd(tasks)
    assert task.action.message.text == message
  end

  test "expand_schedule" do
    schedule = [
      {local_datetime(~N[2018-12-25 05:00:00]), MapSet.new(["open_presents"])}
    ]

    schedule_with_steps = expand_schedule(schedule)

    assert length(schedule_with_steps) == 7

    assert [s1, s2, s3, s4, s5, s6, s7] = schedule_with_steps

    assert_datetime(s1.required_time, local_datetime(~N[2018-12-25 04:30:00]))
    assert_datetime(s1.latest_time, local_datetime(~N[2018-12-25 04:35:00]))
    assert length(s1.tasks) == 1
    assert_tasks(s1.tasks, "Time to wakeup. It is am emergency!")

    assert_datetime(s2.required_time, local_datetime(~N[2018-12-25 04:35:00]))
    assert_datetime(s2.latest_time, local_datetime(~N[2018-12-25 04:40:00]))
    assert length(s2.tasks) == 1
    assert_tasks(s2.tasks, "Time to wakeup the adults.")

    assert_datetime(s3.required_time, local_datetime(~N[2018-12-25 04:40:00]))
    assert_datetime(s3.latest_time, local_datetime(~N[2018-12-25 04:45:00]))
    assert length(s3.tasks) == 1
    assert_tasks(s3.tasks, "Time to wakeup the adults.")

    assert_datetime(s4.required_time, local_datetime(~N[2018-12-25 04:45:00]))
    assert_datetime(s4.latest_time, local_datetime(~N[2018-12-25 04:50:00]))
    assert length(s4.tasks) == 1
    assert_tasks(s4.tasks, "Time to wakeup the adults.")

    assert_datetime(s5.required_time, local_datetime(~N[2018-12-25 04:50:00]))
    assert_datetime(s5.latest_time, local_datetime(~N[2018-12-25 04:55:00]))
    assert length(s5.tasks) == 1
    assert_tasks(s5.tasks, "Time to wakeup the adults.")

    assert_datetime(s6.required_time, local_datetime(~N[2018-12-25 04:55:00]))
    assert_datetime(s6.latest_time, local_datetime(~N[2018-12-25 05:00:00]))
    assert length(s6.tasks) == 1
    assert_tasks(s6.tasks, "Time to wakeup the adults.")

    assert_datetime(s7.required_time, local_datetime(~N[2018-12-25 05:00:00]))
    assert_datetime(s7.latest_time, local_datetime(~N[2018-12-25 06:00:00]))
    assert length(s7.tasks) == 1
    assert_tasks(s7.tasks, "Time to open presents.")
  end

  test "squash_schedule" do
    schedule = [
      %Robotica.Types.MultiStep{
        required_time: local_datetime(~N[2018-12-25 04:35:00]),
        latest_time: local_datetime(~N[2018-12-25 04:40:00]),
        tasks: [
          %Robotica.Types.ScheduledTask{
            locations: ["here"],
            action: %Robotica.Types.Action{},
            frequency: :daily,
            mark: nil
          }
        ]
      },
      %Robotica.Types.MultiStep{
        required_time: local_datetime(~N[2018-12-25 04:35:00]),
        latest_time: local_datetime(~N[2018-12-25 04:40:00]),
        tasks: [
          %Robotica.Types.ScheduledTask{
            locations: ["here"],
            action: %Robotica.Types.Action{},
            frequency: :daily,
            mark: nil
          }
        ]
      },
      %Robotica.Types.MultiStep{
        required_time: local_datetime(~N[2018-12-25 05:35:00]),
        latest_time: local_datetime(~N[2018-12-25 04:40:00]),
        tasks: [
          %Robotica.Types.ScheduledTask{
            locations: ["here"],
            action: %Robotica.Types.Action{},
            frequency: :daily,
            mark: nil
          }
        ]
      }
    ]

    squashed_schedule = squash_schedule(schedule)
    assert length(squashed_schedule) == 2

    [s1, s2] = squashed_schedule

    assert length(s1.tasks) == 2
    assert length(s2.tasks) == 1
  end
end
