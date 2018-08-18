defmodule Robotica.Config do
  @spec replace_values(String.t(), %{required(String.t()) => String.t()}) :: String.t()
  defp replace_values(string, values) do
    Regex.replace(~r/{([a-z_]+)?}/, string, fn _, match ->
      Map.fetch!(values, match)
    end)
  end

  defp map_anything(input, key, required) do
    {value, input} = Map.pop(input, key)

    cond do
      required and is_nil(value) ->
        {:error, "Value #{key} is not supplied."}

      true ->
        {:ok, input, value}
    end
  end

  defp map_used_all_keys(input) do
    if input == %{} do
      {:ok}
    else
      {:error, "Input unused #{inspect(input)}"}
    end
  end

  defp validate_string(value) do
    cond do
      is_nil(value) -> {:ok, value}
      is_binary(value) -> {:ok, value}
      true -> {:error, "Value #{inspect(value)} is not a string."}
    end
  end

  defp validate_boolean(boolean, default \\ nil)

  defp validate_boolean(boolean, _) when is_binary(boolean) do
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
      _ -> {:error, "Invalid boolean #{boolean}."}
    end
  end

  defp validate_boolean(nil, default), do: {:ok, default}
  defp validate_boolean(true, _), do: {:ok, true}
  defp validate_boolean(false, _), do: {:ok, false}
  defp validate_boolean(_, _), do: {:error, "Non-string boolean detected"}

  defp validate_day_of_week(day_of_week) when is_binary(day_of_week) do
    value = day_of_week |> String.slice(0..2) |> String.downcase()

    case value do
      "mon" -> {:ok, 1}
      "tue" -> {:ok, 2}
      "wed" -> {:ok, 3}
      "thu" -> {:ok, 4}
      "fri" -> {:ok, 5}
      "sat" -> {:ok, 6}
      "sun" -> {:ok, 7}
      _ -> {:error, "Invalid week day #{day_of_week}."}
    end
  end

  defp validate_day_of_week(nil), do: {:ok, nil}
  defp validate_day_of_week(_), do: {:error, "Non-string day of week detected"}

  defp validate_date(value) do
    cond do
      is_nil(value) ->
        {:ok, value}

      true ->
        case Date.from_iso8601(value) do
          {:ok, value} -> {:ok, value}
          {:error, _} -> {:error, "Cannot parse date #{value}."}
        end
    end
  end

  defp validate_time(value) do
    cond do
      is_nil(value) ->
        {:ok, value}

      true ->
        case Time.from_iso8601(value) do
          {:ok, value} -> {:ok, value}
          {:error, _} -> {:error, "Cannot parse time #{value}."}
        end
    end
  end

  defp split_time(value) do
    case String.split(value, ":", parts: 3) do
      [hh, mm] -> {:ok, hh, mm, "0"}
      [hh, mm, ss] -> {:ok, hh, mm, ss}
      {:error, _} -> {:error, "Cannot split delta #{value}."}
    end
  end

  defp validate_delta(value) do
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
          :error -> {:error, "Cannot parse value in #{value}."}
          {_, _} -> {:error, "Cannot parse value in #{value}."}
        end
    end
  end

  defp validate_plugin(%{} = item) do
    i = item

    with {:ok, i, module} <- map_anything(i, "module", true),
         {:ok, i, location} <- map_anything(i, "location", true),
         {:ok, i, config} <- map_anything(i, "config", true),
         {:ok} <- map_used_all_keys(i),
         {:ok, module} <- validate_module(module),
         {:ok, location} <- validate_string(location),
         {:ok, config} <- validate_plugin_config(config, module) do
      result = %Robotica.Plugins.Plugin{
        module: module,
        location: location,
        config: config
      }

      {:ok, result}
    else
      {:error, err} -> {:error, err}
    end
  end

  defp validate_plugin(_), do: {:error, "We expected a map."}

  defp validate_plugins([]), do: {:ok, []}

  defp validate_plugins([head | tail]) do
    with {:ok, head} <- validate_plugin(head),
         {:ok, tail} <- validate_plugins(tail) do
      {:ok, [head] ++ tail}
    else
      {:error, err} -> {:error, err}
    end
  end

  defp validate_plugins(_), do: {:error, "Data is not a list."}

  defp validate_module("Audio"), do: {:ok, Robotica.Plugins.Audio}
  defp validate_module("LIFX"), do: {:ok, Robotica.Plugins.LIFX}
  defp validate_module(module), do: {:error, "Unknown module #{module}"}

  defp validate_command_item([]), do: {:ok, []}

  defp validate_command_item([head | tail]) do
    with {:ok, head} <- validate_string(head),
         {:ok, tail} <- validate_command_item(tail) do
      {:ok, [head] ++ tail}
    else
      {:error, err} -> {:error, err}
    end
  end

  defp validate_command([]), do: {:ok, []}

  defp validate_command([head | tail]) do
    with {:ok, head} <- validate_command_item(head),
         {:ok, tail} <- validate_command(tail) do
      {:ok, [head] ++ tail}
    else
      {:error, err} -> {:error, err}
    end
  end

  defp validate_plugin_audio_sounds(%{} = item) do
    i = item

    with {:ok, i, beep} <- map_anything(i, "beep", true),
         {:ok, i, prefix} <- map_anything(i, "prefix", true),
         {:ok, i, repeat} <- map_anything(i, "repeat", true),
         {:ok, i, postfix} <- map_anything(i, "postfix", true),
         {:ok} <- map_used_all_keys(i),
         {:ok, beep} <- validate_string(beep),
         {:ok, prefix} <- validate_string(prefix),
         {:ok, repeat} <- validate_string(repeat),
         {:ok, postfix} <- validate_string(postfix) do
      result = %{
        "beep" => beep,
        "prefix" => prefix,
        "repeat" => repeat,
        "postfix" => postfix
      }

      {:ok, result}
    else
      {:error, err} -> {:error, err}
    end
  end

  defp validate_plugin_audio_sounds(_), do: {:error, "Sounds didn't get a map."}

  defp validate_plugin_audio_commands(%{} = item) do
    i = item

    with {:ok, i, init} <- map_anything(i, "init", true),
         {:ok, i, play} <- map_anything(i, "play", true),
         {:ok, i, say} <- map_anything(i, "say", true),
         {:ok, i, music_play} <- map_anything(i, "music_play", true),
         {:ok, i, music_stop} <- map_anything(i, "music_stop", true),
         {:ok, i, music_pause} <- map_anything(i, "music_pause", true),
         {:ok, i, music_resume} <- map_anything(i, "music_resume", true),
         {:ok} <- map_used_all_keys(i),
         {:ok, init} <- validate_command(init),
         {:ok, play} <- validate_command(play),
         {:ok, say} <- validate_command(say),
         {:ok, music_play} <- validate_command(music_play),
         {:ok, music_pause} <- validate_command(music_pause),
         {:ok, music_resume} <- validate_command(music_resume) do
      result = %Robotica.Plugins.Audio.Commands{
        init: init,
        play: play,
        say: say,
        music_play: music_play,
        music_stop: music_stop,
        music_pause: music_pause,
        music_resume: music_resume
      }

      {:ok, result}
    else
      {:error, err} -> {:error, err}
    end
  end

  defp validate_plugin_audio_commands(_), do: {:error, "Commands didn't get a map."}

  defp validate_plugin_lifx_lights([]), do: {:ok, []}

  defp validate_plugin_lifx_lights([head | tail]) do
    with {:ok, head} <- validate_string(head),
         {:ok, tail} <- validate_plugin_lifx_lights(tail) do
      {:ok, [head] ++ tail}
    else
      {:error, err} -> {:error, err}
    end
  end

  defp validate_plugin_lifx_lights(_), do: {:error, "Data is not a list."}

  defp validate_plugin_config(%{} = item, Robotica.Plugins.Audio) do
    i = item

    with {:ok, i, sounds} <- map_anything(i, "sounds", true),
         {:ok, i, commands} <- map_anything(i, "commands", true),
         {:ok} <- map_used_all_keys(i),
         {:ok, sounds} <- validate_plugin_audio_sounds(sounds),
         {:ok, commands} <- validate_plugin_audio_commands(commands) do
      result = %Robotica.Plugins.Audio.State{
        sounds: sounds,
        commands: commands
      }

      {:ok, result}
    else
      {:error, err} -> {:error, err}
    end
  end

  defp validate_plugin_config(%{} = item, Robotica.Plugins.LIFX) do
    i = item

    with {:ok, i, lights} <- map_anything(i, "lights", true),
         {:ok} <- map_used_all_keys(i),
         {:ok, lights} <- validate_plugin_lifx_lights(lights) do
      result = %Robotica.Plugins.LIFX.State{
        lights: lights
      }

      {:ok, result}
    else
      {:error, err} -> {:error, err}
    end
  end

  defp validate_plugin_config(%{}, plugin), do: {:error, "Unknown plugin #{plugin}."}
  defp validate_plugin_config(_, _), do: {:error, "Plugin didn't get a map."}

  defp validate_config(%{} = item) do
    i = item

    with {:ok, i, plugins} <- map_anything(i, "plugins", true),
         {:ok} <- map_used_all_keys(i),
         {:ok, plugins} <- validate_plugins(plugins) do
      result = %Robotica.Supervisor.State{
        plugins: plugins
      }

      {:ok, result}
    else
      {:error, err} -> {:error, err}
    end
  end

  defp validate_config(_), do: {:error, "We expected a map."}

  defp validate_classification(%{} = item) do
    i = item

    with {:ok, i, start} <- map_anything(i, "start", false),
         {:ok, i, stop} <- map_anything(i, "stop", false),
         {:ok, i, date} <- map_anything(i, "date", false),
         {:ok, i, week_day} <- map_anything(i, "week_day", false),
         {:ok, i, day_of_week} <- map_anything(i, "day_of_week", false),
         {:ok, i, day_type} <- map_anything(i, "day_type", true),
         {:ok} <- map_used_all_keys(i),
         {:ok, start} <- validate_date(start),
         {:ok, stop} <- validate_date(stop),
         {:ok, date} <- validate_date(date),
         {:ok, week_day} <- validate_boolean(week_day),
         {:ok, day_of_week} <- validate_day_of_week(day_of_week),
         {:ok, day_type} <- validate_string(day_type) do
      result = %Robotica.Scheduler.Classification{
        start: start,
        stop: stop,
        date: date,
        week_day: week_day,
        day_of_week: day_of_week,
        day_type: day_type
      }

      {:ok, result}
    else
      {:error, err} -> {:error, err}
    end
  end

  defp validate_classification(_), do: {:error, "We expected a map."}

  defp validate_classifications([]), do: {:ok, []}

  defp validate_classifications([head | tail]) do
    with {:ok, head} <- validate_classification(head),
         {:ok, tail} <- validate_classifications(tail) do
      {:ok, [head] ++ tail}
    else
      {:error, err} -> {:error, err}
    end
  end

  defp validate_sequence_entry([]), do: {:ok, []}

  defp validate_sequence_entry([head | tail]) do
    with {:ok, sequence} <- validate_string(head),
         {:ok, tail} <- validate_sequence_entry(tail) do
      {:ok, [sequence] ++ tail}
    else
      {:error, err} -> {:error, err}
    end
  end

  defp validate_sequence_entry(_), do: {:error, "We expected a list."}

  defp validate_schedule_entry([]), do: {:ok, []}

  defp validate_schedule_entry([{k, v} | tail]) do
    with {:ok, time} <- validate_time(k),
         {:ok, entries} <- validate_sequence_entry(v),
         {:ok, tail} <- validate_schedule_entry(tail) do
      {:ok, [{time, entries}] ++ tail}
    else
      {:error, err} -> {:error, err}
    end
  end

  defp validate_schedule_entry(%{} = item) do
    list = Map.to_list(item)

    with {:ok, value} <- validate_schedule_entry(list) do
      {:ok, Enum.into(value, %{})}
    else
      {:error, err} -> {:error, err}
    end
  end

  defp validate_schedule_entry(_), do: {:error, "Schedule entry didn't get a map."}

  defp validate_schedule([]), do: {:ok, []}

  defp validate_schedule([{k, v} | tail]) do
    with {:ok, classification} <- validate_string(k),
         {:ok, entries} <- validate_schedule_entry(v),
         {:ok, tail} <- validate_schedule(tail) do
      {:ok, [{classification, entries}] ++ tail}
    else
      {:error, err} -> {:error, err}
    end
  end

  defp validate_schedule(%{} = item) do
    list = Map.to_list(item)

    with {:ok, value} <- validate_schedule(list) do
      {:ok, Enum.into(value, %{})}
    else
      {:error, err} -> {:error, err}
    end
  end

  defp validate_locations([]), do: {:ok, []}

  defp validate_locations([head | tail]) do
    with {:ok, head} <- validate_string(head),
         {:ok, tail} <- validate_locations(tail) do
      {:ok, [head] ++ tail}
    else
      {:error, err} -> {:error, err}
    end
  end

  defp validate_locations(_), do: {:error, "We expected a list."}

  defp validate_action(%{} = item) do
    i = item

    with {:ok, i, sound} <- map_anything(i, "sound", false),
         {:ok, i, music} <- map_anything(i, "music", false),
         {:ok, i, message} <- map_anything(i, "message", false),
         {:ok, i, lights} <- map_anything(i, "lights", false),
         {:ok, i, timer_status} <- map_anything(i, "timer_status", false),
         {:ok, i, timer_cancel} <- map_anything(i, "timer_cancel", false),
         {:ok} <- map_used_all_keys(i) do
      result = %Robotica.Plugins.Action{
        sound: sound,
        music: music,
        message: message,
        lights: lights,
        timer_status: timer_status,
        timer_cancel: timer_cancel
      }

      {:ok, result}
    else
      {:error, err} -> {:error, err}
    end
  end

  defp validate_action(_), do: {:error, "We expected a map."}

  defp validate_actions([]), do: {:ok, []}

  defp validate_actions([head | tail]) do
    with {:ok, head} <- validate_action(head),
         {:ok, tail} <- validate_schedule(tail) do
      {:ok, [head] ++ tail}
    else
      {:error, err} -> {:error, err}
    end
  end

  defp validate_actions(_), do: {:error, "We expected a list."}

  def validate_task(%{} = item) do
    i = item

    with {:ok, i, locations} <- map_anything(i, "locations", true),
         {:ok, i, actions} <- map_anything(i, "actions", true),
         {:ok} <- map_used_all_keys(i),
         {:ok, locations} <- validate_locations(locations),
         {:ok, actions} <- validate_actions(actions) do
      result = %Robotica.Plugins.Task{
        locations: locations,
        actions: actions
      }

      {:ok, result}
    else
      {:error, err} -> {:error, err}
    end
  end

  def validate_task(_), do: {:error, "We expected a map."}

  defp validate_sequences_item(%{} = item) do
    i = item

    with {:ok, i, time} <- map_anything(i, "time", true),
         {:ok, i, zero_time} <- map_anything(i, "zero_time", false),
         {:ok, i, locations} <- map_anything(i, "locations", true),
         {:ok, i, actions} <- map_anything(i, "actions", true),
         {:ok, i, load_schedule} <- map_anything(i, "load_schedule", false),
         {:ok} <- map_used_all_keys(i),
         {:ok, time} <- validate_delta(time),
         {:ok, zero_time} <- validate_boolean(zero_time, false),
         {:ok, locations} <- validate_locations(locations),
         {:ok, actions} <- validate_actions(actions),
         {:ok, load_schedule} <- validate_boolean(load_schedule) do
      result = %Robotica.Scheduler.Step{
        time: time,
        zero_time: zero_time,
        locations: locations,
        actions: actions,
        load_schedule: load_schedule
      }

      {:ok, result}
    else
      {:error, err} -> {:error, err}
    end
  end

  defp validate_sequences_item(_), do: {:error, "We expected a map."}

  defp validate_sequences_entry([]), do: {:ok, []}

  defp validate_sequences_entry([head | tail]) do
    with {:ok, head} <- validate_sequences_item(head),
         {:ok, tail} <- validate_sequences_entry(tail) do
      {:ok, [head] ++ tail}
    else
      {:error, err} -> {:error, err}
    end
  end

  defp validate_sequences_entry(_), do: {:error, "Schedule entry didn't get a list."}

  defp validate_sequences([]), do: {:ok, []}

  defp validate_sequences([{k, v} | tail]) do
    with {:ok, classification} <- validate_string(k),
         {:ok, entries} <- validate_sequences_entry(v),
         {:ok, tail} <- validate_sequences(tail) do
      {:ok, [{classification, entries}] ++ tail}
    else
      {:error, err} -> {:error, err}
    end
  end

  defp validate_sequences(%{} = item) do
    list = Map.to_list(item)

    with {:ok, value} <- validate_sequences(list) do
      {:ok, Enum.into(value, %{})}
    else
      {:error, err} -> {:error, err}
    end
  end

  defp validate_sequences(_), do: {:error, "Sequences didn't get a map."}

  def substitutions do
    {:ok, hostname} = :inet.gethostname()
    hostname = to_string(hostname)
    %{
        "hostname" => hostname,
    }
  end

  def configuration do
    filename = Application.get_env(:robotica, :config_file)
    |> replace_values(substitutions())
    {:ok, data} = YamlElixir.read_from_file(filename)
    {:ok, data} = validate_config(data)
    data
  end

  def classifications do
    filename = Application.get_env(:robotica, :classifications_file)
    |> replace_values(substitutions())
    {:ok, data} = YamlElixir.read_from_file(filename)
    {:ok, data} = validate_classifications(data)
    data
  end

  def schedule do
    filename = Application.get_env(:robotica, :schedule_file)
    |> replace_values(substitutions())
    {:ok, data} = YamlElixir.read_from_file(filename)
    {:ok, data} = validate_schedule(data)
    data
  end

  def sequences do
    filename = Application.get_env(:robotica, :sequences_file)
    |> replace_values(substitutions())
    {:ok, data} = YamlElixir.read_from_file(filename)
    {:ok, data} = validate_sequences(data)
    data
  end

end
