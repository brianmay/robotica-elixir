defmodule RoboticaPlugins.Config do
  defmodule Loader do
    alias RoboticaPlugins.Schema

    @spec replace_values(String.t(), %{required(String.t()) => String.t()}) :: String.t()
    defp replace_values(string, values) do
      Regex.replace(~r/{([a-z_]+)?}/, string, fn _, match ->
        Map.fetch!(values, match)
      end)
    end

    defp substitutions do
      {:ok, hostname} = :inet.gethostname()
      hostname = to_string(hostname)

      %{
        "hostname" => hostname
      }
    end

    defp button_task do
      %{
        locations: {{:list, :string}, false},
        devices: {{:list, :string}, false},
        action: {Schema.action_schema(), true}
      }
    end

    defp button do
      %{
        name: {:string, true},
        tasks: {{:list, button_task()}, true}
      }
    end

    defp button_row do
      %{
        name: {:string, true},
        buttons: {{:list, button()}, true}
      }
    end

    defp config_schema do
      %{
        location: {:string, true}
      }
    end

    defp config_location_schema do
      %{
        local_buttons: {{:list, button_row()}, false},
        remote_locations: {{:list, :string}, true}
      }
    end

    defp config_common_schema do
      %{
        locations: {{:map, :string, config_location_schema()}, true},
        local_buttons: {{:list, button_row()}, true},
        remote_buttons: {{:list, button_row()}, true}
      }
    end

    def ui_host_configuration do
      filename =
        Application.get_env(:robotica_plugins, :config_file)
        |> replace_values(substitutions())

      {:ok, data} = RoboticaPlugins.Validation.load_and_validate(filename, config_schema())
      data
    end

    def ui_common_configuration(filename) do
      {:ok, data} = RoboticaPlugins.Validation.load_and_validate(filename, config_common_schema())
      data
    end
  end

  @filename Application.get_env(:robotica_plugins, :config_common_file)
  @external_resource @filename
  @common_config Loader.ui_common_configuration(@filename)

  defp list_or_empty_list(list) do
    case list do
      nil -> []
      list -> list
    end
  end

  defp merge_buttons(lists_of_buttons) do
    Enum.reduce(lists_of_buttons, [], fn buttons, list ->
      buttons = list_or_empty_list(buttons)
      list ++ buttons
    end)
  end

  def ui_configuration(location \\ nil) do
    location =
      case location do
        nil ->
          host_config = Loader.ui_host_configuration()
          host_config.location

        location ->
          location
      end

    common_config = @common_config
    local_config = common_config.locations[location]

    buttons = merge_buttons([common_config.local_buttons, local_config.local_buttons])

    %{
      local_location: location,
      local_buttons: buttons,
      remote_locations: local_config.remote_locations,
      remote_buttons: common_config.remote_buttons
    }
  end
end
