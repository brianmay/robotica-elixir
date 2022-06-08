defmodule Robotica.Config do
  @moduledoc """
  Handle loading of Robotica specific configuration
  """

  alias RoboticaCommon.Schema
  alias RoboticaCommon.Validation

  require Logger

  defmodule Loader do
    @moduledoc """
    Internal loader for Robotica config
    """

    defp classification_schema do
      %{
        struct_type: Robotica.Types.Classification,
        start: {:date, false},
        stop: {:date, false},
        date: {:date, false},
        week_day: {{:boolean, nil}, false},
        day_of_week: {:day_of_week, false},
        if_not_set: {{:list, :string}, false},
        if_set: {{:list, :string}, false},
        add: {{:list, :string}, false},
        delete: {{:list, :string}, false}
      }
    end

    defp classifications_schema do
      {:list, classification_schema()}
    end

    defp schedule_sequence_schema do
      %{
        options: {{:list, :string}, false},
        time: {:time, true}
      }
    end

    defp schedule_block_schema do
      %{
        today: {{:list, :string}, false},
        tomorrow: {{:list, :string}, false},
        sequences: {{:map, :string, schedule_sequence_schema()}, true}
      }
    end

    defp schedule_schema do
      {:list, schedule_block_schema()}
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
        http_url: {:string, true},
        remote_scheduler: {:string, false},
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

    @spec scenes(String.t()) :: map()
    def scenes(filename) do
      {:ok, data} = Validation.load_and_validate(filename, Schema.scenes_schema())
      data
    end
  end

  if Application.compile_env(:robotica_common, :compile_config_files) do
    @filename Application.compile_env(:robotica, :config_file)
    @external_resource @filename
    @config Loader.configuration(@filename)
    defp get_config, do: @config

    @scenes_filename Application.compile_env(:robotica, :scenes_file)
    @external_resource @scenes_filename
    @scenes Loader.scenes(@scenes_filename)
    defp get_scenes, do: @scenes
  else
    defp get_config do
      filename = Application.get_env(:robotica, :config_file)
      Loader.configuration(filename)
    end

    defp get_scenes do
      filename = Application.get_env(:robotica, :scenes_file)
      Loader.configuration(filename)
    end
  end

  @spec get_hosts :: %{required(String.t()) => map()}
  def get_hosts do
    get_config().hosts
  end

  @spec get_host_config :: %{required(atom()) => any()}
  def get_host_config do
    Map.fetch!(get_hosts(), hostname())
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

  @spec http_url :: String.t()
  def http_url do
    get_host_config().http_url
  end

  @spec plugins :: list(Robotica.Plugin.t())
  def plugins do
    get_host_config().plugins
  end

  @spec configuration :: Robotica.Supervisor.Config.t()
  def configuration do
    %Robotica.Supervisor.Config{
      remote_scheduler: get_host_config().remote_scheduler,
      mqtt: get_config().mqtt,
      plugins: plugins()
    }
  end

  @spec get_scene(String.t()) :: list()
  def get_scene(scene_name) do
    case Map.get(get_scenes().scenes, scene_name) do
      nil ->
        Logger.error("Unknown scene name #{scene_name}")
        []

      scenes ->
        scenes
    end
  end

  @spec validate_tasks(map) :: {:error, any} | {:ok, list(RoboticaCommon.Task.t())}
  def validate_tasks(data) do
    Validation.validate_schema(data, {:list, Schema.task_schema()})
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

  @spec validate_mark(map) :: {:error, any} | {:ok, RoboticaCommon.Mark.t()}
  def validate_mark(%{} = data) do
    Validation.validate_schema(data, Schema.mark_schema())
  end
end
