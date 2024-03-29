defmodule Robotica.CommonConfig do
  @moduledoc """
  Common config functions
  """

  alias EventBus.Util.Base62

  defmodule Loader do
    @moduledoc """
    Loader stuff for configuration
    """

    defp button do
      %{
        struct_type: Robotica.Buttons.Config,
        name: {:string, true},
        id: {:string, false},
        location: {:string, false},
        device: {:string, true},
        type: {:string, true},
        action: {:string, true},
        params: {{:map, :string, :any}, false}
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

    defp config_host_schema do
      %{
        default_location: {:string, true},
        schedule_host: {:string, false}
      }
    end

    defp config_common_schema do
      %{
        hosts: {{:map, :string, config_host_schema()}, true},
        locations: {{:map, :string, config_location_schema()}, true}
      }
    end

    def ui_common_configuration(filename) do
      {:ok, data} = RoboticaCommon.Validation.load_and_validate(filename, config_common_schema())
      data
    end
  end

  if Application.compile_env(:robotica_common, :compile_config_files) do
    @filename Application.compile_env(:robotica_common, :config_common_file)
    @external_resource @filename
    @common_config Loader.ui_common_configuration(@filename)
    defp common_config, do: @common_config
  else
    defp common_config do
      filename = Application.get_env(:robotica_common, :config_common_file)
      Loader.ui_common_configuration(filename)
    end
  end

  def hostname do
    case Application.get_env(:robotica_common, :hostname) do
      nil ->
        {:ok, hostname} = :inet.gethostname()
        to_string(hostname)

      hostname ->
        hostname
    end
  end

  def ui_default_host_config do
    Map.fetch!(common_config().hosts, hostname())
  end

  def ui_default_location do
    ui_default_host_config().default_location
  end

  def ui_schedule_hostname do
    case ui_default_host_config().schedule_host do
      nil -> hostname()
      hostname -> hostname
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
        %Robotica.Buttons.Config{} = config ->
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
