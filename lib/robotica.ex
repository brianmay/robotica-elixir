defmodule Robotica do
  use Application

  def start(_type, _args) do
    audio_config = %Robotica.Plugins.Audio.State{
      sounds: %{
        "beep" => "sounds/ding1.wav",
        "prefix" => "sounds/login.wav",
        "repeat" => "sounds/cymbal.wav",
        "postfix" => "sounds/logout.wav"
      },
      commands: %{
        "play" => [
          ["aplay", "{file}"]
        ],
        "say" => [
          ["espeak", "-ven+f5", "-k5", "{text}"]
        ],
        "music_play" => [
          ["mpc", "clear"],
          ["mpc", "load", "{play_list}"],
          ["mpc", "play"]
        ],
        "music_stop" => [
          ["mpc", "stop"]
        ],
        "music_pause" => [
          ["mpc", "pause-if-playing"]
        ],
        "music_resume" => [
          ["mpc", "play"]
        ]
      }
    }

    config = %Robotica.Supervisor.State{
      plugins: [
        %Robotica.Plugins.Plugin{
          module: Robotica.Plugins.Audio,
          location: "Brian",
          config: audio_config
        }
      ],
      location: "Brian"
    }

    Robotica.Supervisor.start_link(config)
  end
end
