defmodule RoboticaCommon.Validation do
  @moduledoc """
  Validate untrusted json fields
  """
  @map_types Application.compile_env(:robotica_common, :map_types)

  defp module_compiled?(module) do
    case Code.ensure_compiled(module) do
      {:module, _} -> true
      _ -> false
    end
  end

  defp plugin_available?(module) do
    case module_compiled?(module) do
      true -> function_exported?(module, :config_schema, 0)
      false -> false
    end
  end

  defp split_time(value) do
    case String.split(value, ":", parts: 3) do
      [hh, mm] -> {:ok, hh, mm, "0"}
      [hh, mm, ss] -> {:ok, hh, mm, ss}
      _ -> {:error, "Cannot split delta #{value}"}
    end
  end

  defp schema_key_to_data_key(key) do
    if is_atom(key) do
      Atom.to_string(key)
    else
      key
    end
  end

  defp validate_kwlist_any(%{}, []), do: {:ok, %{}}

  defp validate_kwlist_any(%{} = data, [{key, value} | tail]) do
    data_key = schema_key_to_data_key(key)
    sub_data = data[data_key]
    {sub_schema, required} = value

    case {required, sub_data} do
      {true, nil} ->
        {:error, "Value #{key} is not provided in #{inspect(data)}"}

      {_, sub_data} ->
        with {:ok, new_head} <- validate_schema(sub_data, sub_schema),
             {:ok, new_tail} <- validate_kwlist_any(data, tail) do
          {:ok, Map.put(new_tail, key, new_head)}
        else
          {:error, err} -> {:error, err}
        end
    end
  end

  defp validate_kwlist(%{}, [], _), do: {:ok, %{}}

  defp validate_kwlist(%{} = raw_data, [_head | _tail] = schema, struct_type) do
    case validate_kwlist_any(raw_data, schema) do
      {:ok, data} ->
        case Keyword.get(@map_types, struct_type) do
          nil ->
            {:ok, data}

          {module, name} ->
            apply(module, name, [raw_data, data])
        end

      {:error, err} ->
        {:error, err}
    end
  end

  defp validate_map([], _, _), do: {:ok, %{}}

  defp validate_map([{key, value} | tail], key_schema, value_schema) do
    with {:ok, new_key} <- validate_schema(key, key_schema),
         {:ok, new_value} <- validate_schema(value, value_schema),
         {:ok, new_tail} <- validate_map(tail, key_schema, value_schema) do
      {:ok, Map.put(new_tail, new_key, new_value)}
    else
      {:error, err} -> {:error, err}
    end
  end

  def validate_schema(nil, {:list, _}), do: {:ok, nil}
  def validate_schema([], {:list, _}), do: {:ok, []}

  def validate_schema([head | tail], {:list, item_schema} = schema) do
    with {:ok, new_head} <- validate_schema(head, item_schema),
         {:ok, new_tail} <- validate_schema(tail, schema) do
      {:ok, [new_head | new_tail]}
    else
      {:error, err} -> {:error, err}
    end
  end

  def validate_schema(value, {:list, _}), do: {:error, "Value #{inspect(value)} is not a list"}

  def validate_schema(nil, %{}), do: {:ok, nil}

  def validate_schema(%{} = data, %{} = schema) do
    {struct_type, schema} = Map.pop(schema, :struct_type)

    remapped_schema =
      Enum.map(schema, fn {k, v} -> {schema_key_to_data_key(k), v} end)
      |> Enum.into(%{})

    # Remove data keys not in schema.
    data = Map.take(data, Map.keys(remapped_schema))

    schema = Map.to_list(schema)

    case validate_kwlist(data, schema, struct_type) do
      {:ok, result} ->
        if is_nil(struct_type) do
          {:ok, result}
        else
          {:ok, struct(struct_type, result)}
        end

      {:error, err} ->
        {:error, err}
    end
  end

  def validate_schema(data, :any), do: {:ok, data}

  def validate_schema(value, %{}), do: {:error, "Value #{inspect(value)} is not a map"}

  def validate_schema(%{} = data, {:map, key_schema, value_schema}) do
    data_keyword_list = Map.to_list(data)
    validate_map(data_keyword_list, key_schema, value_schema)
  end

  def validate_schema(nil, {:map, _, _}), do: {:ok, %{}}

  def validate_schema(value, {:map, _, _}), do: {:error, "Value #{inspect(value)} is not a map"}

  def validate_schema(_, :set_nil), do: {:ok, nil}

  def validate_schema(value, :string) do
    cond do
      is_nil(value) -> {:ok, value}
      is_binary(value) -> {:ok, value}
      true -> {:error, "Value #{inspect(value)} is not a string"}
    end
  end

  def validate_schema(nil, {:integer, default}), do: {:ok, default}

  def validate_schema(value, {:integer, _}) do
    cond do
      is_nil(value) -> {:ok, value}
      is_integer(value) -> {:ok, value}
      true -> {:error, "Value #{inspect(value)} is not a integer"}
    end
  end

  def validate_schema(value, :integer) do
    cond do
      is_nil(value) -> {:ok, value}
      is_integer(value) -> {:ok, value}
      true -> {:error, "Value #{inspect(value)} is not a integer"}
    end
  end

  def validate_schema(value, :integer_or_string) do
    cond do
      is_nil(value) -> {:ok, value}
      is_integer(value) -> {:ok, value}
      true -> {:ok, value}
    end
  end

  def validate_schema(nil, :module), do: {:ok, nil}

  def validate_schema(module, :module) do
    module = String.to_atom("Elixir.#{module}")

    case plugin_available?(module) do
      true -> {:ok, module}
      false -> {:error, "Unknown module #{module}"}
    end
  end

  def validate_schema(nil, :mark_status), do: {:ok, nil}
  def validate_schema("done", :mark_status), do: {:ok, :done}
  def validate_schema("cancelled", :mark_status), do: {:ok, :cancelled}
  def validate_schema(status, :mark_status), do: {:error, "Unknown mark status #{status}"}

  def validate_schema(nil, :task_frequency), do: {:ok, nil}
  def validate_schema("daily", :task_frequency), do: {:ok, :daily}
  def validate_schema("weekly", :task_frequency), do: {:ok, :weekly}
  def validate_schema(tf, :task_frequency), do: {:error, "Unknown task frequency #{tf}"}

  def validate_schema(value, :date_time) do
    cond do
      is_nil(value) ->
        {:ok, value}

      true ->
        case DateTime.from_iso8601(value) do
          {:ok, value, 0} -> {:ok, value}
          {:ok, _, _} -> {:error, "Need to have a UTC datetime."}
          {:error, _} -> {:error, "Cannot parse date time #{value}"}
        end
    end
  end

  def validate_schema(value, :date) do
    cond do
      is_nil(value) ->
        {:ok, value}

      true ->
        case Date.from_iso8601(value) do
          {:ok, value} -> {:ok, value}
          {:error, _} -> {:error, "Cannot parse date #{value}"}
        end
    end
  end

  def validate_schema(value, :time) do
    cond do
      is_nil(value) ->
        {:ok, value}

      true ->
        case Time.from_iso8601(value) do
          {:ok, value} -> {:ok, value}
          {:error, _} -> {:error, "Cannot parse time #{value}"}
        end
    end
  end

  def validate_schema(value, :delta) do
    cond do
      is_nil(value) ->
        {:ok, value}

      true ->
        with {:ok, hh, mm, ss} <- split_time(value),
             {h, ""} <- Integer.parse(hh),
             {m, ""} <- Integer.parse(mm),
             {s, ""} <- Integer.parse(ss) do
          result = h * 60
          result = (result + m) * 60
          result = result + s
          {:ok, result}
        else
          {:error, err} -> {:error, err}
          :error -> {:error, "Cannot parse value in #{value}"}
          {_, _} -> {:error, "Cannot parse value in #{value}"}
        end
    end
  end

  def validate_schema(day_of_week, :day_of_week) when is_binary(day_of_week) do
    value = day_of_week |> String.slice(0..2) |> String.downcase()

    case value do
      "mon" -> {:ok, 1}
      "tue" -> {:ok, 2}
      "wed" -> {:ok, 3}
      "thu" -> {:ok, 4}
      "fri" -> {:ok, 5}
      "sat" -> {:ok, 6}
      "sun" -> {:ok, 7}
      _ -> {:error, "Invalid week day #{day_of_week}"}
    end
  end

  def validate_schema(nil, :day_of_week), do: {:ok, nil}
  def validate_schema(_, :day_of_week), do: {:error, "Non-string day of week detected"}

  # credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity
  def validate_schema(boolean, {:boolean, _}) when is_binary(boolean) do
    value = String.downcase(boolean)

    case value do
      "true" -> {:ok, true}
      "false" -> {:ok, false}
      "t" -> {:ok, true}
      "f" -> {:ok, false}
      "yes" -> {:ok, true}
      "no" -> {:ok, false}
      "y" -> {:ok, true}
      "n" -> {:ok, false}
      _ -> {:error, "Invalid boolean #{boolean}"}
    end
  end

  def validate_schema(nil, {:boolean, default}), do: {:ok, default}
  def validate_schema(true, {:boolean, _}), do: {:ok, true}
  def validate_schema(false, {:boolean, _}), do: {:ok, false}

  def validate_schema(nil, :mark), do: {:ok, nil}
  def validate_schema("done", :mark), do: {:ok, :done}
  def validate_schema("cancelled", :mark), do: {:ok, :cancelled}

  def validate_schema(value, {:boolean, _}),
    do: {:error, "Non-string boolean detected #{inspect(value)}"}

  def validate_schema(value, type),
    do: {:error, "Something went wrong with #{inspect(value)} expected type #{inspect(type)}"}

  def load_and_validate(filename, config_schema) do
    with {:ok, data} <- YamlElixir.read_from_file(filename),
         {:ok, data} <- validate_schema(data, config_schema) do
      {:ok, data}
    else
      {:error, msg} -> {:error, msg}
    end
  end
end
