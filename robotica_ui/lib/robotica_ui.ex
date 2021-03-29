defmodule RoboticaUi do
  @moduledoc """
  Starter application using the Scenic framework.
  """

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    # load the viewport configuration from config
    main_viewport_config = Application.get_env(:robotica_ui, :viewport)

    # start the application with the viewport
    children = [
      {Scenic, viewports: [main_viewport_config]},
      RoboticaUi.Schedule,
      RoboticaUi.Execute,
      RoboticaUi.RootManager
    ]

    EventBus.subscribe({RoboticaUi.RoboticaService, ["^schedule", "^command_task"]})
    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
