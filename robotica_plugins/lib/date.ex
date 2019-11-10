defmodule RoboticaPlugins.Date do
  @moduledoc """
  Provides data/time functions for Robotica.
  """

  @timezone Application.get_env(:robotica_plugins, :timezone)

  @doc """
  Converts an UTC date time to a local Date for tomorrow.

  Note: 13:00 UTC is midnight in Australia/Melbourne timezone at this date.

  iex> import RoboticaPlugins.Date
  iex> tomorrow(~U[2019-11-09 12:00:00Z])
  ~D[2019-11-10]

  iex> import RoboticaPlugins.Date
  iex> tomorrow(~U[2019-11-09 13:00:00Z])
  ~D[2019-11-11]
  """
  @spec tomorrow(DateTime.t()) :: Date.t()
  def tomorrow(date_time) do
    Calendar.DateTime.shift_zone!(date_time, @timezone)
    |> Calendar.Date.next_day!()
  end

  @doc """
  Find the local date next Monday after the specified UTC date time.

  If it is Monday, return the next Monday.

  iex> import RoboticaPlugins.Date
  iex> next_monday(~U[2019-11-10 12:00:00Z])
  ~D[2019-11-11]

  iex> import RoboticaPlugins.Date
  iex> next_monday(~U[2019-11-10 13:00:00Z])
  ~D[2019-11-18]
  """
  @spec next_monday(DateTime.t()) :: Date.t()
  def next_monday(date_time) do
    # M 1 --> +7
    # T 2 --> +6
    # W 3 --> +5
    # T 4 --> +4
    # F 5 --> +3
    # S 6 --> +2
    # S 7 --> +1

    date_time = Calendar.DateTime.shift_zone!(date_time, @timezone)
    day_of_week = Date.day_of_week(date_time)
    add_days = 7 - day_of_week + 1
    Calendar.Date.add!(date_time, add_days)
  end

  @doc """
  Find the UTC date time at midnight for the specified local date.

  iex> import RoboticaPlugins.Date
  iex> result = midnight_utc(~D[2019-11-10])
  iex> %{time_zone: "UTC"} = result
  iex> %{result| time_zone: "Etc/UTC"}
  ~U[2019-11-09 13:00:00+00:00]
  """
  @spec midnight_utc(Date.t()) :: DateTime.t()
  def midnight_utc(date) do
    Calendar.DateTime.from_date_and_time_and_zone!(date, ~T[00:00:00], @timezone)
    |> Calendar.DateTime.shift_zone!("UTC")
  end
end
