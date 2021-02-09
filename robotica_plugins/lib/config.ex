defmodule RoboticaPlugins.Config do
  alias EventBus.Util.Base62

  defmodule Loader do
    defp button do
      %{
        struct_type: RoboticaPlugins.Buttons.Config,
        name: {:string, true},
        id: {:string, false},
        location: {:string, false},
        device: {:string, true},
        type: {:string, true},
        action: {:string, true}
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
        local_buttons: {{:list, button_row()}, true}
      }
    end

    defp config_common_schema do
      %{
        hosts: {{:map, :string, :string}, true},
        locations: {{:map, :string, config_location_schema()}, true}
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

  @spec update_if_nil(map(), atom(), (() -> any())) :: map()
  defp update_if_nil(map, key, function) do
    value =
      case Map.fetch!(map, key) do
        nil -> function.()
        value -> value
      end

    Map.put(map, key, value)
  end

  defp update_row(row, location) do
    buttons =
      Enum.map(row.buttons, fn
        %RoboticaPlugins.Buttons.Config{} = config ->
          config
          |> update_if_nil(:location, fn -> location end)
          |> update_if_nil(:id, fn -> Base62.unique_id() end)
      end)

    Map.put(row, :buttons, buttons)
  end

  def ui_local_buttons(location) do
    common_config = common_config()
    local_config = Map.fetch!(common_config.locations, location)
    Enum.map(local_config.local_buttons, fn row -> update_row(row, location) end)
  end

  def ui_locations do
    common_config = common_config()
    Map.keys(common_config.locations)
  end
end
