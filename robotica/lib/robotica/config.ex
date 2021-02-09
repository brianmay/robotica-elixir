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

    @spec configuration(String.t()) :: map()
    def configuration(filename) do
      {:ok, data} = Validation.load_and_validate(filename, config_schema())
      data
    end

    @spec classifications(String.t()) :: map()
    def classifications(filename) do
      {:ok, data} = Validation.load_and_validate(filename, classifications_schema())
      data
    end

    @spec schedule(String.t()) :: map()
    def schedule(filename) do
      {:ok, data} = Validation.load_and_validate(filename, schedule_schema())
      data
    end

    @spec sequences(String.t()) :: map()
    def sequences(filename) do
      {:ok, data} = Validation.load_and_validate(filename, sequences_schema())
      data
    end
  end

  @filename Application.get_env(:robotica, :config_file)
  @external_resource @filename
  @config Loader.configuration(@filename)

  @spec get_hosts :: %{required(String.t()) => map()}
  def get_hosts() do
    @config.hosts
  end

  @spec hostname :: String.t()
  defp hostname do
    case Application.get_env(:robotica, :hostname) do
      nil ->
        {:ok, hostname} = :inet.gethostname()
        to_string(hostname)

      hostname ->
        hostname
    end
  end

  @spec plugins :: list(RoboticaPlugins.Plugin.t())
  defp plugins do
    hosts = get_hosts()
    Map.fetch!(hosts, hostname()).plugins
  end

  @spec configuration :: Robotica.Supervisor.State.t()
  def configuration do
    %Robotica.Supervisor.State{
      mqtt: @config.mqtt,
      plugins: plugins()
    }
  end

  @spec validate_task(map) :: {:error, any} | {:ok, RoboticaPlugins.Task.t()}
  def validate_task(%{} = data) do
    Validation.validate_schema(data, Schema.task_schema())
  end

  @spec validate_audio_command(map) :: {:error, any} | {:ok, any}
  def validate_audio_command(%{} = data) do
    Validation.validate_schema(data, Schema.audio_action_schema())
  end

  @spec validate_hdmi_command(map) :: {:error, any} | {:ok, any}
  def validate_hdmi_command(%{} = data) do
    Validation.validate_schema(data, Schema.hdmi_action_schema())
  end

  @spec validate_device_command(map) :: {:error, any} | {:ok, any}
  def validate_device_command(%{} = data) do
    Validation.validate_schema(data, Schema.device_action_schema())
  end

  @spec validate_lights_command(map) :: {:error, any} | {:ok, any}
  def validate_lights_command(%{} = data) do
    Validation.validate_schema(data, Schema.lights_action_schema())
  end

  @spec validate_mark(map) :: {:error, any} | {:ok, RoboticaPlugins.Mark.t()}
  def validate_mark(%{} = data) do
    Validation.validate_schema(data, Schema.mark_schema())
  end
end
