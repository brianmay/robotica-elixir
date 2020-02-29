defmodule Robotica.Scheduler.Classifier do
  alias Robotica.Types

  defp is_week_day?(date) do
    case Date.day_of_week(date) do
      dow when dow in 1..5 -> true
      _ -> false
    end
  end

  @filename Application.get_env(:robotica, :classifications_file)
  @external_resource @filename
  @data Robotica.Config.Loader.classifications(@filename)

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

  defp is_excluded_entry?(classification_names, %Types.Classification{} = classification) do
    exclude_list =
      if is_nil(classification.exclude) do
        []
      else
        classification.exclude
      end

    Enum.any?(exclude_list, fn exclude_name ->
      Enum.member?(classification_names, exclude_name)
    end)
  end

  defp reject_excluded(classifications) do
    classification_names =
      Enum.map(classifications, fn classification -> classification.day_type end)

    Enum.reject(classifications, fn classification ->
      is_excluded_entry?(classification_names, classification)
    end)
  end

  def classify_date(date) do
    @data
    |> Enum.filter(fn classification -> is_in_classification?(classification, date) end)
    |> reject_excluded()
    |> Enum.map(fn classification -> classification.day_type end)
  end
end
