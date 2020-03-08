use Mix.Config

config :robotica_ui, :viewport, %{
  name: :main_viewport,
  size: {800, 480},
  default_scene: {RoboticaUi.Scene.Clock, nil},
  drivers: [
    %{
      module: Scenic.Driver.Nerves.Rpi
    },
    %{
      module: Scenic.Driver.Nerves.Touch,
      opts: [
        device: "FT5406 memory based driver",
        calibration: {{1, 0, 0}, {1, 0, 0}}
      ]
    }
  ]
}

config :tzdata, :data_dir, "/root/elixir_tzdata_data"
