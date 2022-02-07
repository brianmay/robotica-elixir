defmodule Robotica.Scheduler.Schedule do
  @moduledoc """
  Process a schedule entry
  """

  alias Robotica.Config.Loader
  alias Robotica.Scheduler.Classifier

  @timezone Application.compile_env(:robotica, :timezone)

  if Application.compile_env(:robotica_common, :compile_config_files) do
    @filename Application.compile_env(:robotica, :schedule_file)
    @external_resource @filename
    @data Loader.schedule(@filename)
    defp get_data, do: @data
  else
    defp get_data do
      filename = Application.get_env(:robotica, :schedule_file)
      Loader.schedule(filename)
    end
  end

  defp convert_time_to_utc(date, time) do
    {:ok, naive_date_time} = NaiveDateTime.new(date, time)
    {:ok, date_time} = DateTime.from_naive(naive_date_time, @timezone)
    {:ok, utc_date_time} = DateTime.shift_zone(date_time, "UTC")
    utc_date_time
  end

  def check_block_date(classifications, requirements) do
    if requirements == nil do
      true
    else
      today = MapSet.new(requirements)
      intersection = MapSet.intersection(classifications, today)
      MapSet.size(intersection) > 0
    end
  end

  def check_block(block, date) do
    today = Classifier.classify_date(date)
    tomorrow = Classifier.classify_date(Date.add(date, 1))
    check_block_date(today, block.today) and check_block_date(tomorrow, block.tomorrow)
  end

  def transform_sequence(seq_name, seq_options, date) do
    options = MapSet.new(seq_options.options || [])
    datetime = convert_time_to_utc(date, seq_options.time)
    {datetime, seq_name, options}
  end

  def get_schedule(date) do
    get_data()
    |> Enum.filter(fn block -> check_block(block, date) end)
    |> Enum.reduce(%{}, fn block, map -> Map.merge(map, block.sequences) end)
    |> Enum.map(fn {seq_name, seq_options} -> transform_sequence(seq_name, seq_options, date) end)
    |> Enum.reduce(%{}, fn {datetime, seq_name, options}, acc ->
      action = {seq_name, options}
      Map.update(acc, datetime, [action], &[action | &1])
    end)
    |> Map.to_list()
    |> Enum.sort(fn x, y -> DateTime.compare(elem(x, 0), elem(y, 0)) == :lt end)
  end
end
