defmodule Robotica.Scheduler.Schedule.Test do
  use ExUnit.Case, async: true

  import Robotica.Scheduler.Schedule

  def local_datetime(dt) do
    dt = DateTime.from_naive!(dt, "Australia/Melbourne")
    DateTime.shift_zone!(dt, "UTC")
  end

  def assert_datetime(dt1, dt2) do
    assert DateTime.compare(dt1, dt2) == :eq, "#{dt1} != #{dt2}"
  end

  test "every day" do
    schedule = get_schedule(~D[2018-12-24])

    assert length(schedule) == 2

    [wakeup, sleep] = schedule

    assert {time, sequence} = wakeup
    assert sequence == [{"wake_up", MapSet.new()}]
    assert_datetime(time, local_datetime(~N[2018-12-24 08:30:00]))

    assert {time, sequence} = sleep
    assert sequence == [{"sleep", MapSet.new()}]
    assert_datetime(time, local_datetime(~N[2018-12-24 20:30:00]))
  end

  test "christmas day" do
    schedule = get_schedule(~D[2018-12-25])

    assert length(schedule) == 3

    [presents, wakeup, sleep] = schedule

    assert {time, sequence} = presents
    assert sequence == [{"presents", MapSet.new()}]
    assert_datetime(time, local_datetime(~N[2018-12-25 08:00:00]))

    assert {time, sequence} = wakeup
    assert sequence == [{"wake_up", MapSet.new()}]
    assert_datetime(time, local_datetime(~N[2018-12-25 08:30:00]))

    assert {time, sequence} = sleep
    assert sequence == [{"sleep", MapSet.new()}]
    assert_datetime(time, local_datetime(~N[2018-12-25 20:30:00]))
  end

  test "boxing day" do
    schedule = get_schedule(~D[2018-12-26])

    assert length(schedule) == 2

    [wakeup, sleep] = schedule

    assert {time, sequence} = wakeup
    assert sequence == [{"wake_up", MapSet.new()}]
    assert_datetime(time, local_datetime(~N[2018-12-26 12:30:00]))

    assert {time, sequence} = sleep
    assert sequence == [{"sleep", MapSet.new()}]
    assert_datetime(time, local_datetime(~N[2018-12-26 20:30:00]))
  end
end
