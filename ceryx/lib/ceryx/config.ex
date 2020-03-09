defmodule Ceryx.Config do
  alias RoboticaPlugins.Validation

  defmodule Loader do
    defp mqtt_config_schema do
      %{
        host: {:string, true},
        port: {:integer, true},
        user_name: {:string, false},
        password: {:string, false},
        ca_cert_file: {:string, true}
      }
    end

    defp config_schema do
      %{
        struct_type: Ceryx.Supervisor.State,
        mqtt: {mqtt_config_schema(), true}
      }
    end

    def configuration(filename) do
      {:ok, data} = Validation.load_and_validate(filename, config_schema())
      data
    end
  end

  if Application.get_env(:ceryx, :config_file) do
    @filename Application.get_env(:ceryx, :config_file)
    @external_resource @filename
    @config Loader.configuration(@filename)
    def configuration(), do: @config
  else
    def configuration() do
      filename = Application.get_env(:ceryx, :config_file)
      Loader.configuration(filename)
    end
  end
end
