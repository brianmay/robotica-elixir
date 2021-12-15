# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
import Config

# Configure the main viewport for the Scenic application
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
