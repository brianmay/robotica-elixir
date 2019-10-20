defmodule RoboticaFace.Config do
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

  defp button do
    %{
      name: {:string, true},
      action: {Schema.action_schema(), true}
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
      local_locations: {{:list, :string}, true},
      local_buttons: {{:list, button_row()}, true},
      remote_locations: {{:list, :string}, true},
      remote_buttons: {{:list, button_row()}, true}
    }
  end

  def configuration do
    filename =
      Application.get_env(:robotica_ui, :config_file)
      |> replace_values(substitutions())

    {:ok, data} = YamlElixir.read_from_file(filename)
    {:ok, data} = RoboticaPlugins.Validation.validate_schema(data, config_schema())
    data
  end
end
