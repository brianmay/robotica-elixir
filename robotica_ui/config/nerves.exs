import Config

case Mix.target() do
  :host ->
    nil

  :rpi3 ->
    config :robotica_ui, :viewport, %{
      name: :main_viewport,
      size: {800, 480},
      default_scene: {RoboticaUi.Scene.Clock, nil},
      drivers: [
        %{
          module: Scenic.Driver.Local,
          name: :main_driver
        }
      ]
    }
end
