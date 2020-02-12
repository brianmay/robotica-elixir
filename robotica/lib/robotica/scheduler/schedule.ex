defmodule Robotica.Scheduler.Schedule do
  @timezone Application.get_env(:robotica, :timezone)

  @filename Application.get_env(:robotica, :schedule_file)
  @external_resource @filename
  @data Robotica.Config.schedule(@filename)

  defp convert_time_to_utc(date, time) do
    {:ok, naive_date_time} = NaiveDateTime.new(date, time)
    {:ok, date_time} = DateTime.from_naive(naive_date_time, @timezone)
    {:ok, utc_date_time} = DateTime.shift_zone(date_time, "UTC")
    utc_date_time
  end

  defp parse_action(action) do
    {name, remaining} =
      case String.split(action, "(", parts: 2) do
        [name] -> {name, ")"}
        [name, remaining] -> {name, remaining}
      end

    case String.split(remaining, ")", parts: 2) do
      [""] -> {:error, "Right bracket not found"}
      ["", _] -> {:ok, name, MapSet.new()}
      [options, ""] -> {:ok, name, String.split(options, ",") |> MapSet.new()}
      [_, extra] -> {:error, "Extra text found #{extra}"}
    end
  end

  defp add_schedule(expanded_schedule, date, schedule, classification) do
    schedule
    |> Map.get(classification, %{})
    |> Enum.map(fn {time, actions} -> {convert_time_to_utc(date, time), actions} end)
    |> Enum.reduce(expanded_schedule, fn {datetime, actions}, acc ->
      Enum.reduce(actions, acc, fn action, acc ->
        {:ok, name, options} = parse_action(action)
        Map.put(acc, name, {datetime, options})
      end)
    end)
  end

  def get_schedule(classifications, date) do
    s = @data

    expanded_schedule = add_schedule(%{}, date, s, "*")

    expanded_schedule =
      classifications
      |> Enum.reduce(expanded_schedule, fn c, acc -> add_schedule(acc, date, s, c) end)
      |> Enum.reduce(%{}, fn {name, {datetime, options}}, acc ->
        action = {name, options}
        Map.update(acc, datetime, [action], &[action | &1])
      end)
      |> Map.to_list()
      |> Enum.sort(fn x, y -> Calendar.DateTime.before?(elem(x, 0), elem(y, 0)) end)

    expanded_schedule
  end
end
