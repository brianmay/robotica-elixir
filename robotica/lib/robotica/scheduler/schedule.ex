defmodule Robotica.Scheduler.Schedule do
  @moduledoc """
  Process a schedule entry
  """

  defmodule Schedule do
    @moduledoc """
    A complete unexpanded schedule
    """
    alias Robotica.Scheduler.Classifier.ClassifiedDate

    @type schedule_t ::
            list(
              {time :: DateTime.t(),
               options :: {name :: String.t(), options :: MapSet.t(String.t())}}
            )

    @type t :: %__MODULE__{
            today: ClassifiedDate.t(),
            tomorrow: ClassifiedDate.t(),
            schedule: schedule_t()
          }
    @enforce_keys [:today, :tomorrow, :schedule]
    defstruct [:today, :tomorrow, :schedule]
  end

  alias Robotica.Config.Loader
  alias Robotica.Scheduler.Classifier.ClassifiedDate

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

  defp check_block_date(classifications, requirements) do
    if requirements == nil do
      true
    else
      today = MapSet.new(requirements)
      intersection = MapSet.intersection(classifications, today)
      MapSet.size(intersection) > 0
    end
  end

  defp check_block(block, classifications_today, classifications_tomorrow) do
    check_block_date(classifications_today, block.today) and
      check_block_date(classifications_tomorrow, block.tomorrow)
  end

  defp transform_sequence(seq_name, seq_options, date) do
    options = MapSet.new(seq_options.options || [])
    datetime = convert_time_to_utc(date, seq_options.time)

    %{
      seq_options
      | time: datetime,
        options: options
    }
    |> Map.put(:name, seq_name)
  end

  @spec get_schedule(today :: ClassifiedDate.t(), tomorrow :: ClassifiedDate.t()) :: Schedule.t()

  def get_schedule(c_today, c_tomorrow) do
    schedule =
      get_data()
      |> Enum.filter(fn block ->
        check_block(block, c_today.classifications, c_tomorrow.classifications)
      end)
      |> Enum.reduce(%{}, fn block, map -> Map.merge(map, block.sequences) end)
      |> Enum.map(fn {seq_name, seq_options} ->
        transform_sequence(seq_name, seq_options, c_today.date)
      end)
      |> Enum.reduce(%{}, fn values, acc ->
        datetime = values.time
        name = values.name
        options = values.options

        action = {name, options}
        Map.update(acc, datetime, [action], &[action | &1])
      end)
      |> Map.to_list()
      |> Enum.sort(fn x, y -> DateTime.compare(elem(x, 0), elem(y, 0)) == :lt end)

    %Schedule{
      today: c_today,
      tomorrow: c_tomorrow,
      schedule: schedule
    }
  end
end
