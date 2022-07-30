defmodule Robotica.Schema do
  @moduledoc """
  Common json schemas
  """
  defp sound_action_schema do
    :string
  end

  def music_action_schema do
    %{
      play_list: {:string, false},
      stop: {{:boolean, false}, false}
    }
  end

  def message_action_schema do
    %{
      text: {:string, true}
    }
  end

  def volume_action_schema do
    %{
      music: {:integer, false},
      message: {:integer, false}
    }
  end

  def lights_color do
    %{
      brightness: {:integer_or_string, true},
      hue: {:integer_or_string, true},
      saturation: {:integer_or_string, true},
      kelvin: {:integer_or_string, true},
      alpha: {:integer_or_string, false}
    }
  end

  def repeat_colors do
    %{
      count: {:integer_or_string, true},
      colors: {{:list, lights_color()}, true}
    }
  end

  def frame do
    %{
      sleep: {:integer, true},
      repeat: {:integer, false},
      color: {lights_color(), false},
      colors_index: {:integer, false},
      colors: {{:list, repeat_colors()}, false}
    }
  end

  def animation do
    %{
      repeat: {:integer, false},
      frames: {{:list, frame()}, true}
    }
  end

  def lights_action_schema do
    %{
      type: {:string, false},
      stop_scenes: {{:list, :string}, false},
      stop_priorities: {{:list, :integer}, false},
      scene: {:string, false},
      priority: {:integer, false},
      action: {:string, false},
      color: {lights_color(), false},
      colors_index: {:integer, false},
      colors: {{:list, repeat_colors()}, false},
      duration: {:integer, false},
      animation: {animation(), false}
    }
  end

  def scene_schema do
    %{
      locations: {{:list, :string}, false},
      devices: {{:list, :string}, false},
      lights: {lights_action_schema(), true}
    }
  end

  def scenes_schema do
    %{
      scenes: {{:map, :string, {:list, scene_schema()}}, true}
    }
  end

  def hdmi_action_schema do
    %{
      type: {:string, false},
      input: {:integer, true},
      output: {:integer, true}
    }
  end

  def device_action_schema do
    %{
      type: {:string, false},
      action: {:string, true}
    }
  end

  def audio_action_schema do
    %{
      type: {:string, false},
      sound: {sound_action_schema(), false},
      music: {music_action_schema(), false},
      message: {message_action_schema(), false},
      volume: {volume_action_schema(), false},
      pre_tasks: {{:list, task_schema()}, false},
      post_tasks: {{:list, task_schema()}, false}
    }
  end

  def task_schema do
    %{
      struct_type: Robotica.Types.Task,
      payload_json: {{:map, :string, :any}, true},
      locations: {{:list, :string}, false},
      devices: {{:list, :string}, false},
      topics: {{:list, :string}, false}
    }
  end

  def mark_schema do
    %{
      struct_type: Robotica.Mark,
      id: {:string, true},
      status: {:mark_status, true},
      start_time: {:date_time, true},
      stop_time: {:date_time, true}
    }
  end

  def source_step_schema do
    %{
      struct_type: Robotica.Types.SourceStep,
      if: {{:list, :string}, false},
      zero_time: {{:boolean, false}, false},
      required_time: {:delta, true},
      latest_time: {:delta, false},
      tasks: {{:list, task_schema()}, true},
      repeat_time: {:delta, false},
      repeat_count: {{:integer, 0}, false},
      classifications: {{:list, :string}, false},
      options: {{:list, :string}, false}
    }
  end

  def scheduled_step_schema do
    %{
      struct_type: Robotica.Types.ScheduledStep,
      required_time: {:date_time, true},
      latest_time: {:date_time, true},
      tasks: {{:list, task_schema()}, true},
      id: {:string, true},
      mark: {:mark, false},
      repeat_number: {{:integer, nil}, false}
    }
  end

  def validate_scheduled_steps(data) do
    RoboticaCommon.Validation.validate_schema(data, {:list, scheduled_step_schema()})
  end
end
