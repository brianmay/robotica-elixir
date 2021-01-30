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
        local_buttons: {{:list, button_row()}, true},
        remote_locations: {{:list, :string}, false}
      }
    end

    defp config_common_schema do
      %{
        hosts: {{:map, :string, :string}, true},
        locations: {{:map, :string, config_location_schema()}, true},
        remote_buttons: {{:list, button_row()}, false}
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

  defp hostname do
    {:ok, hostname} = :inet.gethostname()
    to_string(hostname)
  end

  def ui_default_location do
    case Application.get_env(:robotica_plugins, :location) do
      nil ->
        Map.fetch!(common_config().hosts, hostname())

      location ->
        location
    end
  end

  def ui_local_buttons(location) do
    common_config = common_config()
    local_config = Map.fetch!(common_config.locations, location)
    local_config.local_buttons
  end

  def ui_locations do
    common_config = common_config()
    Map.keys(common_config.locations)
  end
end
