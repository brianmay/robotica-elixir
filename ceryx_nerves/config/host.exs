use Mix.Config

config :robotica_ui, :viewport, %{
  name: :main_viewport,
  size: {800, 480},
  default_scene: {RoboticaUi.Scene.Schedule, nil},
  drivers: [
    %{
      module: Scenic.Driver.Glfw,
      name: :glfw,
      opts: [resizeable: false, title: "robotica_ui"]
    }
  ]
}

config :ceryx,
  config_file: "../config/ceryx.yaml"

config :robotica_plugins,
  config_common_file: "../config/common.yaml"
