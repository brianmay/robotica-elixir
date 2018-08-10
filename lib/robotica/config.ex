defmodule Robotica.Config do
  defp map_anything(input, key, required) do
    {value, input} = Map.pop(input, key)

    cond do
      required and is_nil(value) ->
        {:error, "Value #{key} is not supplied."}

      true ->
        {:ok, input, value}
    end
  end

  defp map_string(input, key, required) do
    with {:ok, input, value} <- map_anything(input, key, required),
         {:ok, value} <- validate_string(value) do
      {:ok, input, value}
    else
      err -> err
    end
  end

  defp map_plugins(input, key, required) do
    with {:ok, input, value} <- map_anything(input, key, required),
         {:ok, value} <- validate_plugins(value) do
      {:ok, input, value}
    else
      err -> err
    end
  end

  defp map_module(input, key, required) do
    with {:ok, input, value} <- map_anything(input, key, required),
         {:ok, value} <- validate_module(value) do
      {:ok, input, value}
    else
      err -> err
    end
  end

  defp map_plugin_config(input, key, required, module) do
    with {:ok, input, value} <- map_anything(input, key, required),
         {:ok, value} <- validate_plugin_config(value, module) do
      {:ok, input, value}
    else
      err -> err
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

  defp validate_plugin(%{} = item) do
    i = item

    with {:ok, i, module} <- map_module(i, "module", true),
         {:ok, i, location} <- map_string(i, "location", true),
         {:ok, i, config} <- map_plugin_config(i, "config", true, module),
         {:ok} <- map_used_all_keys(i) do
      result = %Robotica.Plugins.Plugin{
        module: module,
        location: location,
        config: config
      }

      {:ok, result}
    else
      err -> err
    end
  end

  defp validate_plugin(_), do: {:error, "We expected a map."}

  defp validate_plugins([]), do: {:ok, []}

  defp validate_plugins([head | tail]) do
    with {:ok, head} <- validate_plugin(head),
         {:ok, tail} <- validate_plugins(tail) do
      {:ok, [head] ++ tail}
    else
      err -> err
    end
  end

  defp validate_plugins(_), do: {:error, "Data is not a list."}

  defp validate_module("Audio"), do: {:ok, Robotica.Plugins.Audio}
  defp validate_module(module), do: {:error, "Unknown module #{module}"}

  defp validate_plugin_config(%{} = item, Robotica.Plugins.Audio) do
    i = item

    with {:ok, i, sounds} <- map_anything(i, "sounds", true),
         {:ok, i, commands} <- map_anything(i, "commands", true),
         {:ok} <- map_used_all_keys(i) do
      result = %Robotica.Plugins.Audio.State{
        sounds: sounds,
        commands: commands
      }

      {:ok, result}
    else
      err -> err
    end
  end

  defp validate_plugin_config(%{}, _), do: {:error, "Unknown plugin."}
  defp validate_plugin_config(_, _), do: {:error, "Plugin didn't get a map."}

  defp validate_config(%{} = item) do
    i = item

    with {:ok, i, plugins} <- map_plugins(i, "plugins", true),
         {:ok, i, location} <- map_string(i, "location", true),
         {:ok} <- map_used_all_keys(i) do
      result = %Robotica.Supervisor.State{
        plugins: plugins,
        location: location
      }

      {:ok, result}
    else
      err -> err
    end
  end

  defp validate_config(_), do: {:error, "We expected a map."}

  defp get_configuration do
    filename = Application.get_env(:robotica, :config_file)
    {:ok, data} = YamlElixir.read_from_file(filename)
    {:ok, data} = validate_config(data)
    data
  end

  defmacro configuration do
    data = get_configuration()
    Macro.escape(data)
  end
end
