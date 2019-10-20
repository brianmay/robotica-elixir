defmodule Robotica.Config do
  alias RoboticaPlugins.Validation
  alias RoboticaPlugins.Schema

  @spec replace_values(String.t(), %{required(String.t()) => String.t()}) :: String.t()
  defp replace_values(string, values) do
    Regex.replace(~r/{([a-z_]+)?}/, string, fn _, match ->
      Map.fetch!(values, match)
    end)
  end

  defp classification_schema do
    %{
      struct_type: Robotica.Types.Classification,
      start: {:date, false},
      stop: {:date, false},
      date: {:date, false},
      week_day: {{:boolean, nil}, false},
      day_of_week: {:day_of_week, false},
      exclude: {{:list, :string}, false},
      day_type: {:string, true}
    }
  end

  defp classifications_schema do
    {:list, classification_schema()}
  end

  defp schedule_schema do
    {:map, :string, {:map, :time, {:list, :string}}}
  end

  defp scheduled_task_schema do
    %{
      struct_type: RoboticaPlugins.ScheduledTask,
      action: {Schema.action_schema(), true},
      locations: {{:list, :string}, true},
      repeat_time: {:delta, false},
      repeat_count: {{:integer, 0}, false}
    }
  end

  defp task_schema do
    %{
      struct_type: RoboticaPlugins.Task,
      action: {Schema.action_schema(), true},
      locations: {{:list, :string}, true}
    }
  end

  defp mark_schema do
    %{
      struct_type: RoboticaPlugins.Mark,
      id: {:string, true},
      status: {:mark_status, true},
      start_time: {:date_time, true},
      stop_time: {:date_time, true}
    }
  end

  defp step_schema do
    %{
      struct_type: RoboticaPlugins.ScheduledStep,
      zero_time: {{:boolean, false}, false},
      required_time: {:delta, true},
      latest_time: {:delta, false},
      task: {scheduled_task_schema(), true}
    }
  end

  defp sequences_schema do
    {:map, :string, {:list, step_schema()}}
  end

  defp plugin_schema do
    %{
      struct_type: Robotica.Plugin,
      config: {:set_nil, true},
      location: {:string, true},
      module: {:module, true}
    }
  end

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
      struct_type: Robotica.Supervisor.State,
      plugins: {{:list, plugin_schema()}, true},
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
    filename =
      Application.get_env(:robotica, :config_file)
      |> replace_values(substitutions())

    {:ok, data} = YamlElixir.read_from_file(filename)
    {:ok, data} = Validation.validate_schema(data, config_schema())
    data
  end

  def classifications do
    filename =
      Application.get_env(:robotica, :classifications_file)
      |> replace_values(substitutions())

    {:ok, data} = YamlElixir.read_from_file(filename)
    {:ok, data} = Validation.validate_schema(data, classifications_schema())
    data
  end

  def schedule do
    filename =
      Application.get_env(:robotica, :schedule_file)
      |> replace_values(substitutions())

    {:ok, data} = YamlElixir.read_from_file(filename)
    {:ok, data} = Validation.validate_schema(data, schedule_schema())
    data
  end

  def sequences do
    filename =
      Application.get_env(:robotica, :sequences_file)
      |> replace_values(substitutions())

    {:ok, data} = YamlElixir.read_from_file(filename)
    {:ok, data} = Validation.validate_schema(data, sequences_schema())
    data
  end

  def validate_task(%{} = data) do
    Validation.validate_schema(data, task_schema())
  end

  def validate_mark(%{} = data) do
    Validation.validate_schema(data, mark_schema())
  end
end
