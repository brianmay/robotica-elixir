defmodule RoboticaFace.Date do
  @moduledoc false

  def tomorrow(date_time) do
    Calendar.DateTime.shift_zone!(date_time, "Australia/Melbourne")
    |> Calendar.Date.next_day!()
  end

  def next_monday(date_time) do
    # M 1 --> +7
    # T 2 --> +6
    # W 3 --> +5
    # T 4 --> +4
    # F 5 --> +3
    # S 6 --> +2
    # S 7 --> +1

    date_time = Calendar.DateTime.shift_zone!(date_time, "Australia/Melbourne")
    day_of_week = Date.day_of_week(date_time)
    add_days = 7 - day_of_week + 1
    Calendar.Date.add!(date_time, add_days)
  end

  def midnight_utc(date) do
    Calendar.DateTime.from_date_and_time_and_zone!(date, ~T[00:00:00], "Australia/Melbourne")
    |> Calendar.DateTime.shift_zone!("UTC")
  end
end
