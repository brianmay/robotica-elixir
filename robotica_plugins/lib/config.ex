defmodule RoboticaPlugins.Config do
  defmodule Loader do
    alias RoboticaPlugins.Schema

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

    defp config_location_schema do
      %{
        local_buttons: {{:list, button_row()}, false},
        remote_locations: {{:list, :string}, true}
      }
    end

    defp config_common_schema do
      %{
        hosts: {{:map, :string, :string}, true},
        locations: {{:map, :string, config_location_schema()}, true},
        local_buttons: {{:list, button_row()}, true},
        remote_buttons: {{:list, button_row()}, true}
      }
    end

    def ui_common_configuration(filename) do
      {:ok, data} = RoboticaPlugins.Validation.load_and_validate(filename, config_common_schema())
      data
    end
  end

  if Application.get_env(:robotica_plugins, :config_common_file) do
    @filename Application.get_env(:robotica_plugins, :config_common_file)
    @external_resource @filename
    @common_config Loader.ui_common_configuration(@filename)
    defp common_config(), do: @common_config
  else
    defp common_config() do
      filename = Application.get_env(:robotica_plugins, :config_common_file)
      Loader.ui_common_configuration(filename)
    end
  end

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

  defp hostname do
    {:ok, hostname} = :inet.gethostname()
    to_string(hostname)
  end

  def ui_location do
    case Application.get_env(:robotica_plugins, :location) do
      nil ->
        Map.fetch!(common_config().hosts, hostname())

      location ->
        location
    end
  end

  def ui_configuration(location \\ nil) do
    location =
      case location do
        nil -> ui_location()
        location -> location
      end

    common_config = common_config()
    local_config = Map.fetch!(common_config.locations, location)

    buttons = merge_buttons([common_config.local_buttons, local_config.local_buttons])

    %{
      local_location: location,
      local_buttons: buttons,
      remote_locations: local_config.remote_locations,
      remote_buttons: common_config.remote_buttons
    }
  end
end
