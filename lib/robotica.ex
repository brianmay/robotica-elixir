defmodule Robotica do
  use Application

  def start(_type, _args) do
    :ok = Lifx.Client.start

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
        "music_pause" => [
          ["mpc", "pause-if-playing"]
        ],
        "music_resume" => [
          ["mpc", "play"]
        ]
      }
    }
    lifx_config = %Robotica.Plugins.LIFX.State{
        lights: ["Brian"]
    }

    config = %Robotica.Supervisor.State{
      plugins: [
        %Robotica.Plugins.Plugin{
          module: Robotica.Plugins.Audio,
          location: "Brian",
          config: audio_config
        },
        %Robotica.Plugins.Plugin{
          module: Robotica.Plugins.LIFX,
          location: "Brian",
          config: lifx_config
        }
      ],
      location: "Brian"
    }

    Robotica.Supervisor.start_link(config)
  end
end
