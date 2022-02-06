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
    include_list = Map.get(classification, :if)

    if include_list == nil do
      true
    else
      Enum.any?(include_list, fn include_name ->
        Enum.member?(classification_names, include_name)
      end)
    end
  end

  defp is_excluded_entry?(classification_names, %Types.Classification{} = classification) do
    exclude_list = Map.get(classification, :if_not) || []

    Enum.any?(exclude_list, fn exclude_name ->
      Enum.member?(classification_names, exclude_name)
    end)
  end

  defp is_duplicated_entry?(classification_names, %Types.Classification{} = classification) do
    Enum.member?(classification_names, classification.day_type)
  end

  @spec put_list(MapSet.t(), list()) :: MapSet.t()
  defp put_list(mapset, list) do
    Enum.reduce(list, mapset, fn item, mapset -> MapSet.put(mapset, item) end)
  end

  @spec list_to_mapset(list(Types.Classification.t())) :: MapSet.t()
  defp list_to_mapset(classifications) do
    Enum.reduce(classifications, MapSet.new(), fn classification, mapset ->
      MapSet.put(mapset, classification.day_type)
    end)
  end

  @spec remove_replaced(list(Types.Classification.t()), Types.Classification.t()) ::
          list(Types.Classification.t())
  defp remove_replaced(classifications, replaces) do
    delete = put_list(MapSet.new(), replaces.replace || [])
    Enum.reject(classifications, fn item -> MapSet.member?(delete, item.day_type) end)
  end

  def classify_date(date) do
    get_data()
    |> Enum.reduce([], fn classification, list ->
      names = list_to_mapset(list)

      add =
        cond do
          not is_in_classification?(classification, date) -> false
          not is_included_entry?(names, classification) -> false
          is_excluded_entry?(names, classification) -> false
          is_duplicated_entry?(names, classification) -> false
          true -> true
        end

      if add do
        list = remove_replaced(list, classification)
        [classification | list]
      else
        list
      end
    end)
    |> Enum.map(fn classification -> classification.day_type end)
    |> MapSet.new()
  end
end
