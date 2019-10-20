defmodule RoboticaPlugins.Schema do
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

  def lights_color do
    %{
      brightness: {:integer, true},
      hue: {:integer, true},
      saturation: {:integer, true},
      kelvin: {:integer, true}
    }
  end

  def lights_action_schema do
    %{
      action: {:string, true},
      color: {lights_color(), false},
      duration: {:integer, false}
    }
  end

  def action_schema do
    %{
      struct_type: RoboticaPlugins.Action,
      sound: {sound_action_schema(), false},
      music: {music_action_schema(), false},
      message: {message_action_schema(), false},
      lights: {lights_action_schema(), false}
    }
  end
end
