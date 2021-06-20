use Mix.Config

case Mix.Project.config()[:target] do
  "host" ->
    nil

  "rpi3" ->
    config :robotica_ui, :viewport, %{
      name: :main_viewport,
      size: {800, 480},
      default_scene: {RoboticaUi.Scene.Schedule, nil},
      drivers: [
        %{
          module: Scenic.Driver.Nerves.Rpi
        },
        %{
          module: Scenic.Driver.Nerves.Touch,
          opts: [
            device: "raspberrypi-ts",
            calibration: {{1, 0, 0}, {1, 0, 0}}
          ]
        }
      ]
    }
end
