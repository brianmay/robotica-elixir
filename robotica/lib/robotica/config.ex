defmodule Robotica.Config do
  alias RoboticaPlugins.Schema
  alias RoboticaPlugins.Validation

  defmodule Loader do
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

    defp sequences_schema do
      {:map, :string, {:list, Schema.source_step_schema()}}
    end

    defp plugin_schema do
      %{
        struct_type: Robotica.Plugin,
        config: {:set_nil, true},
        location: {:string, true},
        device: {:string, true},
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

    defp host_schema do
      %{
        plugins: {{:list, plugin_schema()}, true}
      }
    end

    defp config_schema do
      %{
        hosts: {{:map, :string, host_schema()}, true},
        mqtt: {mqtt_config_schema(), true}
      }
    end

    def configuration(filename) do
      {:ok, data} = Validation.load_and_validate(filename, config_schema())
      data
    end

    def classifications(filename) do
      {:ok, data} = Validation.load_and_validate(filename, classifications_schema())
      data
    end

    def schedule(filename) do
      {:ok, data} = Validation.load_and_validate(filename, schedule_schema())
      data
    end

    def sequences(filename) do
      {:ok, data} = Validation.load_and_validate(filename, sequences_schema())
      data
    end
  end

  @filename Application.get_env(:robotica, :config_file)
  @external_resource @filename
  @config Loader.configuration(@filename)

  defp hostname do
    {:ok, hostname} = :inet.gethostname()
    to_string(hostname)
  end

  defp plugins do
    Map.fetch!(@config.hosts, hostname()).plugins
  end

  def configuration do
    %Robotica.Supervisor.State{
      mqtt: @config.mqtt,
      plugins: plugins()
    }
  end

  def validate_task(%{} = data) do
    Validation.validate_schema(data, Schema.task_schema())
  end

  def validate_mark(%{} = data) do
    Validation.validate_schema(data, Schema.mark_schema())
  end
end
