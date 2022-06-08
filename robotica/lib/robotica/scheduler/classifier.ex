defmodule Robotica.Scheduler.Classifier do
  @moduledoc """
  Process schedule classifier days
  """
  alias Robotica.Config.Loader
  alias Robotica.Types

  defp is_week_day?(date) do
    case Date.day_of_week(date) do
      dow when dow in 1..5 -> true
      _ -> false
    end
  end

  if Application.compile_env(:robotica_common, :compile_config_files) do
    @filename Application.compile_env(:robotica, :classifications_file)
    @external_resource @filename
    @data Loader.classifications(@filename)
    defp get_data, do: @data
  else
    defp get_data do
      filename = Application.get_env(:robotica, :classifications_file)
      Loader.classifications(filename)
    end
  end

  defp is_date_in_classification?(%Types.Classification{} = classification, date) do
    cond do
      not is_nil(classification.date) ->
        case Date.compare(date, classification.date) do
          :eq -> true
          _ -> false
        end

      true ->
        true
    end
  end

  defp is_date_start_ok?(%Types.Classification{} = classification, date) do
    cond do
      not is_nil(classification.start) ->
        case Date.compare(date, classification.start) do
          a when a in [:gt, :eq] ->
            true

          _ ->
            false
        end

      true ->
        true
    end
  end

  defp is_date_stop_ok?(%Types.Classification{} = classification, date) do
    cond do
      not is_nil(classification.stop) ->
        case Date.compare(date, classification.stop) do
          b when b in [:lt, :eq] ->
            true

          _ ->
            false
        end

      true ->
        true
    end
  end

  defp is_week_day_in_classification?(%Types.Classification{} = classification, date) do
    cond do
      is_nil(classification.week_day) ->
        true

      classification.week_day == true ->
        is_week_day?(date)

      classification.week_day == false ->
        not is_week_day?(date)
    end
  end

  defp is_day_of_week_in_classification?(%Types.Classification{} = classification, date) do
    cond do
      is_nil(classification.day_of_week) -> true
      classification.day_of_week == Date.day_of_week(date) -> true
      true -> false
    end
  end

  defp is_in_classification?(%Types.Classification{} = classification, date) do
    with true <- is_date_in_classification?(classification, date),
         true <- is_date_start_ok?(classification, date),
         true <- is_date_stop_ok?(classification, date),
         true <- is_week_day_in_classification?(classification, date),
         true <- is_day_of_week_in_classification?(classification, date) do
      true
    else
      false -> false
    end
  end

  defp is_included_entry?(classification_names, %Types.Classification{} = classification) do
    include_list = Map.get(classification, :if_set)

    if include_list == nil do
      true
    else
      Enum.any?(include_list, fn include_name ->
        Enum.member?(classification_names, include_name)
      end)
    end
  end

  defp is_excluded_entry?(classification_names, %Types.Classification{} = classification) do
    exclude_list = Map.get(classification, :if_not_set) || []

    Enum.any?(exclude_list, fn exclude_name ->
      Enum.member?(classification_names, exclude_name)
    end)
  end

  @spec put_list(MapSet.t(String.t()), list()) :: MapSet.t(String.t())
  defp put_list(mapset, list) do
    Enum.reduce(list, mapset, fn item, mapset -> MapSet.put(mapset, item) end)
  end

  @spec process_add(MapSet.t(String.t()), Types.Classification.t()) :: MapSet.t(String.t())
  defp process_add(classifications, replaces) do
    add = put_list(MapSet.new(), replaces.add || [])
    MapSet.union(classifications, add)
  end

  @spec process_delete(MapSet.t(String.t()), Types.Classification.t()) :: MapSet.t(String.t())
  defp process_delete(classifications, replaces) do
    delete = put_list(MapSet.new(), replaces.delete || [])
    MapSet.difference(classifications, delete)
  end

  @spec classify_date(any) :: MapSet.t(String.t())
  def classify_date(date) do
    get_data()
    |> Enum.reduce(MapSet.new(), fn classification, names ->
      do_process =
        cond do
          not is_in_classification?(classification, date) -> false
          not is_included_entry?(names, classification) -> false
          is_excluded_entry?(names, classification) -> false
          true -> true
        end

      if do_process do
        names
        |> process_add(classification)
        |> process_delete(classification)
      else
        names
      end
    end)
  end
end
