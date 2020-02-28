defmodule Ceryx.Config do
  alias RoboticaPlugins.Validation
  alias RoboticaPlugins.String

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

  defp substitutions do
    {:ok, hostname} = :inet.gethostname()
    hostname = to_string(hostname)

    %{
      "hostname" => hostname
    }
  end

  def configuration do
    filename = Application.get_env(:ceryx, :config_file)
    {:ok, filename} = String.replace_values(filename, substitutions())
    {:ok, data} = Validation.load_and_validate(filename, config_schema())
    data
  end
end
