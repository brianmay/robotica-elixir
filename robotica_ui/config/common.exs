# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
import Config

config :scenic, :assets, module: RoboticaUi.Assets

# Configure the main viewport for the Scenic application
config :robotica_ui, :viewport, %{
  name: :main_viewport,
  size: {800, 480},
  default_scene: {RoboticaUi.Scene.Clock, nil},
  drivers: [
    %{
      module: Scenic.Driver.Local,
      name: :main_driver,
      window: [resizeable: false, title: "robotica_ui"]
    }
  ]
}
