defmodule RoboticaPlugins.Date do
  @moduledoc """
  Provides data/time functions for Robotica.
  """

  @spec get_timezone :: String.t()
  def get_timezone, do: Application.get_env(:robotica_common, :timezone)

  @doc """
  Converts an UTC date time to a local Date for today.

  Note: 13:00 UTC is midnight in Australia/Melbourne timezone at this date.

  iex> import RoboticaPlugins.Date
  iex> today(~U[2019-11-09 12:00:00Z])
  ~D[2019-11-09]

  iex> import RoboticaPlugins.Date
  iex> today(~U[2019-11-09 13:00:00Z])
  ~D[2019-11-10]
  """
  @spec today(DateTime.t()) :: Date.t()
  def today(date_time) do
    {:ok, local_date_time} = DateTime.shift_zone(date_time, get_timezone())
    Date.add(local_date_time, 0)
  end

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
    {:ok, local_date_time} = DateTime.shift_zone(date_time, get_timezone())
    Date.add(local_date_time, 1)
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

    {:ok, date_time} = DateTime.shift_zone(date_time, get_timezone())
    day_of_week = Date.day_of_week(date_time)
    add_days = 7 - day_of_week + 1
    Date.add(date_time, add_days)
  end

  @doc """
  Find the UTC date time at midnight for the specified local date.

  iex> import RoboticaPlugins.Date
  iex> midnight_utc(~D[2019-11-10])
  ~U[2019-11-09 13:00:00+00:00]
  """
  @spec midnight_utc(Date.t()) :: DateTime.t()
  def midnight_utc(date) do
    {:ok, naive_date_time} = NaiveDateTime.new(date, ~T[00:00:00])
    {:ok, local_date_time} = DateTime.from_naive(naive_date_time, get_timezone())
    {:ok, utc_date_time} = DateTime.shift_zone(local_date_time, "Etc/UTC")
    utc_date_time
  end
end
