defmodule Robotica.Scheduler.Schedule do
  @timezone Application.get_env(:robotica, :timezone)

  @filename Application.get_env(:robotica, :schedule_file)
  @external_resource @filename
  @data Robotica.Config.schedule(@filename)

  defp convert_time_to_utc(date, time) do
    Calendar.DateTime.from_date_and_time_and_zone!(date, time, @timezone)
    |> Calendar.DateTime.shift_zone!("UTC")
  end

  defp add_schedule(date, scheduled, action, name) do
    action = Map.get(action, name, %{})

    action =
      action
      |> Enum.map(fn {k, v} -> {convert_time_to_utc(date, k), v} end)
      |> Enum.reduce(%{}, fn {k, vs}, acc ->
        Enum.reduce(vs, acc, fn v, acc -> Map.put(acc, v, k) end)
      end)

    Map.merge(scheduled, action)
  end

  def get_schedule(classifications, date) do
    a = @data

    schedule = add_schedule(date, %{}, a, "*")

    schedule =
      Enum.reduce(classifications, schedule, fn v, acc -> add_schedule(date, acc, a, v) end)
      |> Enum.reduce(%{}, fn {k, v}, acc ->
        Map.update(acc, v, MapSet.new([k]), &MapSet.put(&1, k))
      end)
      |> Map.to_list()
      |> Enum.sort(fn x, y -> Calendar.DateTime.before?(elem(x, 0), elem(y, 0)) end)

    schedule
  end
end
