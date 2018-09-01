defmodule Robotica.Config do
  @spec replace_values(String.t(), %{required(String.t()) => String.t()}) :: String.t()
  defp replace_values(string, values) do
    Regex.replace(~r/{([a-z_]+)?}/, string, fn _, match ->
      Map.fetch!(values, match)
    end)
  end

  defp split_time(value) do
    case String.split(value, ":", parts: 3) do
      [hh, mm] -> {:ok, hh, mm, "0"}
      [hh, mm, ss] -> {:ok, hh, mm, ss}
      {:error, _} -> {:error, "Cannot split delta #{value}"}
    end
  end

  defp command_list do
    {:list, {:list, :string}}
  end

  defp commands do
    %{
      struct_type: Robotica.Plugins.Audio.Commands,
      init: {command_list(), true},
      music_pause: {command_list(), true},
      music_play: {command_list(), true},
      music_resume: {command_list(), true},
      music_stop: {command_list(), true},
      play: {command_list(), true},
      say: {command_list(), true}
    }
  end

  defp sounds do
    %{
      "beep" => {:string, true},
      "postfix" => {:string, true},
      "prefix" => {:string, true},
      "repeat" => {:string, true}
    }
  end

  defp plugin_audio_schema do
    %{
      struct_type: Robotica.Plugins.Audio.State,
      commands: {commands(), true},
      sounds: {sounds(), true}
    }
  end

  defp plugin_lifx_schema do
    %{
      struct_type: Robotica.Plugins.LIFX.State,
      lights: {{:list, :string}, true}
    }
  end

  defp plugin_mqtt_schema do
    %{
      struct_type: Robotica.Plugins.MQTT.State
    }
  end

  defp classification_schema do
    %{
      struct_type: Robotica.Scheduler.Classification,
      start: {:date, false},
      stop: {:date, false},
      date: {:date, false},
      week_day: {{:boolean, nil}, false},
      day_of_week: {:day_of_week, false},
      exclude: {{:list, :string}, false},
      day_type: {:string, true}
    }
  end

  defp classifications_schema do
    {:list, classification_schema()}
  end

  defp schedule_schema do
    {:map, :string, {:map, :time, {:list, :string}}}
  end

  defp sound_action_schema do
    :string
  end

  defp music_action_schema do
    %{
      play_list: {:string, false},
      stop: {{:boolean, false}, false}
    }
  end

  defp message_action_schema do
    %{
      text: {:string, true}
    }
  end

  defp lights_color do
    %{
      brightness: {:integer, true},
      hue: {:integer, true},
      saturation: {:integer, true},
      kelvin: {:integer, true}
    }
  end

  defp lights_action_schema do
    %{
      action: {:string, true},
      color: {lights_color(), false}
    }
  end

  defp timer_status_action_schema do
    %{
      name: {:string, true},
      time_left: {:integer, true},
      time_total: {:integer, true},
      epoch_minute: {:integer, true},
      epoch_finish: {:integer, true}
    }
  end

  defp timer_cancel_action_schema do
    %{
      name: {:string, true},
      message: {:string, true}
    }
  end

  defp action_schema do
    %{
      struct_type: Robotica.Plugins.Action,
      sound: {sound_action_schema(), false},
      music: {music_action_schema(), false},
      message: {message_action_schema(), false},
      lights: {lights_action_schema(), false},
      timer_warn: {timer_status_action_schema(), false},
      timer_status: {timer_status_action_schema(), false},
      timer_cancel: {timer_cancel_action_schema(), false}
    }
  end

  defp task_schema do
    %{
      struct_type: Robotica.Executor.Task,
      actions: {{:list, action_schema()}, true},
      locations: {{:list, :string}, true}
    }
  end

  defp step_schema do
    %{
      struct_type: Robotica.Scheduler.Step,
      zero_time: {{:boolean, false}, false},
      time: {:delta, true},
      task: {task_schema(), true}
    }
  end

  defp sequences_schema do
    {:map, :string, {:list, step_schema()}}
  end

  defp module_to_schema(Robotica.Plugins.Audio), do: {:ok, plugin_audio_schema()}
  defp module_to_schema(Robotica.Plugins.LIFX), do: {:ok, plugin_lifx_schema()}
  defp module_to_schema(Robotica.Plugins.MQTT), do: {:ok, plugin_mqtt_schema()}
  defp module_to_schema(module), do: {:error, "Unknown module #{inspect(module)}"}

  defp plugin_schema do
    %{
      struct_type: Robotica.Plugins.Plugin,
      config: {:set_nil, true},
      location: {:string, true},
      module: {:module, true}
    }
  end

  defp config_schema do
    %{
      struct_type: Robotica.Supervisor.State,
      plugins: {{:list, plugin_schema()}, true}
    }
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

    case {required, data} do
      {true, nil} ->
        {:error, "Value #{key} is not provided"}

      {_, data} ->
        with {:ok, new_head} <- validate_schema(sub_data, sub_schema),
             {:ok, new_tail} <- validate_kwlist_any(data, tail) do
          {:ok, Map.put(new_tail, key, new_head)}
        else
          {:error, err} -> {:error, err}
        end
    end
  end

  defp validate_kwlist(%{}, [], _), do: {:ok, %{}}

  defp validate_kwlist(%{} = data, [_head | _tail] = schema, Robotica.Plugins.Plugin) do
    with {:ok, result} <- validate_kwlist_any(data, schema),
         config <- Map.fetch!(data, "config"),
         {:ok, config_schema} <- module_to_schema(result.module),
         {:ok, config} <- validate_schema(config, config_schema) do
      {:ok, Map.put(result, :config, config)}
    else
      {:error, err} -> {:error, err}
    end
  end

  defp validate_kwlist(%{} = data, [_head | _tail] = schema, _) do
    validate_kwlist_any(data, schema)
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

  defp validate_schema(nil, {:list, _}), do: {:ok, nil}
  defp validate_schema([], {:list, _}), do: {:ok, []}

  defp validate_schema([head | tail], {:list, item_schema} = schema) do
    with {:ok, new_head} <- validate_schema(head, item_schema),
         {:ok, new_tail} <- validate_schema(tail, schema) do
      {:ok, [new_head | new_tail]}
    else
      {:error, err} -> {:error, err}
    end
  end

  defp validate_schema(value, {:list, _}), do: {:error, "Value #{inspect(value)} is not a list"}

  defp validate_schema(nil, %{}), do: {:ok, nil}

  defp validate_schema(%{} = data, %{} = schema) do
    {struct_type, schema} = Map.pop(schema, :struct_type)

    remapped_schema =
      Enum.map(schema, fn {k, v} -> {schema_key_to_data_key(k), v} end)
      |> Enum.into(%{})

    data_keys = MapSet.new(Map.keys(data))
    schema_keys = MapSet.new(Map.keys(remapped_schema))
    unwanted_keys = MapSet.difference(data_keys, schema_keys)

    if MapSet.size(unwanted_keys) == 0 do
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
    else
      {:error,
       "Map #{inspect(struct_type)} has keys #{inspect(unwanted_keys)} that are not supported"}
    end
  end

  defp validate_schema(value, %{}), do: {:error, "Value #{inspect(value)} is not a map"}

  defp validate_schema(%{} = data, {:map, key_schema, value_schema}) do
    data_keyword_list = Map.to_list(data)
    validate_map(data_keyword_list, key_schema, value_schema)
  end

  defp validate_schema(value, {:map, _, _}), do: {:error, "Value #{inspect(value)} is not a map"}

  defp validate_schema(_, :set_nil), do: {:ok, nil}

  defp validate_schema(value, :string) do
    cond do
      is_nil(value) -> {:ok, value}
      is_binary(value) -> {:ok, value}
      true -> {:error, "Value #{inspect(value)} is not a string"}
    end
  end

  defp validate_schema(value, :integer) do
    cond do
      is_nil(value) -> {:ok, value}
      is_integer(value) -> {:ok, value}
      true -> {:error, "Value #{inspect(value)} is not a integer"}
    end
  end

  defp validate_schema("Audio", :module), do: {:ok, Robotica.Plugins.Audio}
  defp validate_schema("LIFX", :module), do: {:ok, Robotica.Plugins.LIFX}
  defp validate_schema("MQTT", :module), do: {:ok, Robotica.Plugins.MQTT}
  defp validate_schema(module, :module), do: {:error, "Unknown module #{module}"}

  defp validate_schema(value, :date) do
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

  defp validate_schema(value, :time) do
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

  defp validate_schema(value, :delta) do
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

  defp validate_schema(day_of_week, :day_of_week) when is_binary(day_of_week) do
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

  defp validate_schema(nil, :day_of_week), do: {:ok, nil}
  defp validate_schema(_, :day_of_week), do: {:error, "Non-string day of week detected"}

  defp validate_schema(boolean, {:boolean, _}) when is_binary(boolean) do
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

  defp validate_schema(nil, {:boolean, default}), do: {:ok, default}
  defp validate_schema(true, {:boolean, _}), do: {:ok, true}
  defp validate_schema(false, {:boolean, _}), do: {:ok, false}

  defp validate_schema(value, {:boolean, _}),
    do: {:error, "Non-string boolean detected #{inspect(value)}"}

  defp validate_schema(value, type),
    do: {:error, "Something went wrong with #{inspect(value)} expected type #{inspect(type)}"}

  defp substitutions do
    {:ok, hostname} = :inet.gethostname()
    hostname = to_string(hostname)

    %{
      "hostname" => hostname
    }
  end

  def configuration do
    filename =
      Application.get_env(:robotica, :config_file)
      |> replace_values(substitutions())

    {:ok, data} = YamlElixir.read_from_file(filename)
    {:ok, data} = validate_schema(data, config_schema())
    data
  end

  def classifications do
    filename =
      Application.get_env(:robotica, :classifications_file)
      |> replace_values(substitutions())

    {:ok, data} = YamlElixir.read_from_file(filename)
    {:ok, data} = validate_schema(data, classifications_schema())
    data
  end

  def schedule do
    filename =
      Application.get_env(:robotica, :schedule_file)
      |> replace_values(substitutions())

    {:ok, data} = YamlElixir.read_from_file(filename)
    {:ok, data} = validate_schema(data, schedule_schema())
    data
  end

  def sequences do
    filename =
      Application.get_env(:robotica, :sequences_file)
      |> replace_values(substitutions())

    {:ok, data} = YamlElixir.read_from_file(filename)
    {:ok, data} = validate_schema(data, sequences_schema())
    data
  end

  def validate_task(%{} = data) do
    validate_schema(data, task_schema())
  end
end
