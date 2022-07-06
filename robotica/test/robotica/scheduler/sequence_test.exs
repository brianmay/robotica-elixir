defmodule Robotica.Scheduler.Sequence.Test do
  use ExUnit.Case, async: true

  alias Robotica.Scheduler.Classifier.ClassifiedDate
  alias Robotica.Scheduler.Schedule.Schedule
  import Robotica.Scheduler.Sequence

  def local_datetime(dt) do
    dt = DateTime.from_naive!(dt, "Australia/Melbourne")
    DateTime.shift_zone!(dt, "UTC")
  end

  def assert_datetime(dt1, dt2) do
    assert DateTime.compare(dt1, dt2) == :eq, "#{dt1} != #{dt2}"
  end

  def assert_tasks(tasks, message) do
    task = hd(tasks)
    assert task.command["message"]["text"] == message
  end

  test "expand_schedule" do
    schedule = %Schedule{
      today: %ClassifiedDate{
        date: ~D[2018-12-25],
        classifications: MapSet.new(["christmas"])
      },
      tomorrow: %ClassifiedDate{
        date: ~D[2018-12-26],
        classifications: MapSet.new(["boxing"])
      },
      schedule: [
        {local_datetime(~N[2018-12-25 05:00:00]), [{"open_presents", MapSet.new()}]}
      ]
    }

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

  test "sort_schedule" do
    schedule = [
      %Robotica.Types.ScheduledStep{
        required_time: local_datetime(~N[2018-12-25 04:35:00]),
        latest_time: local_datetime(~N[2018-12-25 04:40:00]),
        id: "1",
        tasks: [
          %Robotica.Types.Task{
            locations: ["here"],
            devices: ["here"],
            command: %{}
          }
        ]
      },
      %Robotica.Types.ScheduledStep{
        required_time: local_datetime(~N[2018-12-25 03:35:00]),
        latest_time: local_datetime(~N[2018-12-25 03:40:00]),
        id: "2",
        tasks: [
          %Robotica.Types.Task{
            locations: ["here"],
            devices: ["here"],
            command: %{}
          }
        ]
      },
      %Robotica.Types.ScheduledStep{
        required_time: local_datetime(~N[2018-12-25 06:35:00]),
        latest_time: local_datetime(~N[2018-12-25 06:40:00]),
        id: "3",
        tasks: [
          %Robotica.Types.Task{
            locations: ["here"],
            devices: ["here"],
            command: %{}
          }
        ]
      }
    ]

    sorted_schedule = sort_schedule(schedule)
    assert length(sorted_schedule) == 3

    [s1, s2, s3] = sorted_schedule

    assert s1.id == "2"
    assert s2.id == "1"
    assert s3.id == "3"
  end
end
