defmodule RoboticaPlugins.Schema do
  defp sound_action_schema do
    :string
  end

  def music_action_schema do
    %{
      play_list: {:string, false},
      stop: {{:boolean, false}, false},
      volume: {:integer, false}
    }
  end

  def message_action_schema do
    %{
      text: {:string, true},
      volume: {:integer, false}
    }
  end

  def lights_color do
    %{
      brightness: {:integer_or_string, true},
      hue: {:integer_or_string, true},
      saturation: {:integer_or_string, true},
      kelvin: {:integer_or_string, true}
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
      name: {:string, true},
      repeat: {:integer, false},
      frames: {{:list, frame()}, true}
    }
  end

  def lights_action_schema do
    %{
      stop: {{:list, :string}, false},
      action: {:string, true},
      color: {lights_color(), false},
      colors_index: {:integer, false},
      colors: {{:list, repeat_colors()}, false},
      animation: {animation(), false},
      duration: {:integer, false}
    }
  end

  def hdmi_action_schema do
    %{
      source: {:integer, true}
    }
  end

  def device_action_schema do
    %{
      action: {:string, true}
    }
  end

  def action_schema do
    %{
      struct_type: RoboticaPlugins.Action,
      sound: {sound_action_schema(), false},
      music: {music_action_schema(), false},
      message: {message_action_schema(), false},
      lights: {lights_action_schema(), false},
      hdmi: {hdmi_action_schema(), false},
      device: {device_action_schema(), false}
    }
  end

  def task_schema do
    %{
      struct_type: RoboticaPlugins.Task,
      action: {action_schema(), true},
      locations: {{:list, :string}, true},
      devices: {{:list, :string}, false}
    }
  end

  def mark_schema do
    %{
      struct_type: RoboticaPlugins.Mark,
      id: {:string, true},
      status: {:mark_status, true},
      start_time: {:date_time, true},
      stop_time: {:date_time, true}
    }
  end

  def source_step_schema do
    %{
      struct_type: RoboticaPlugins.SourceStep,
      zero_time: {{:boolean, false}, false},
      required_time: {:delta, true},
      latest_time: {:delta, false},
      tasks: {{:list, task_schema()}, true},
      repeat_time: {:delta, false},
      repeat_count: {{:integer, 0}, false},
      options: {{:list, :string}, false}
    }
  end

  def scheduled_step_schema do
    %{
      struct_type: RoboticaPlugins.ScheduledStep,
      required_time: {:date_time, true},
      latest_time: {:date_time, true},
      tasks: {{:list, task_schema()}, true},
      id: {:string, true},
      mark: {:mark, false},
      repeat_number: {{:integer, nil}, false}
    }
  end
end
