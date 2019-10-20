defmodule RoboticaUi do
  @moduledoc """
  Starter application using the Scenic framework.
  """

  def get_tortoise_client_id do
    {:ok, hostname} = :inet.gethostname()
    hostname = to_string(hostname)
    "robotica_ui-#{hostname}"
  end

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    # load the viewport configuration from config
    main_viewport_config = Application.get_env(:robotica_ui, :viewport)

    # start the application with the viewport
    children = [
      supervisor(Scenic, viewports: [main_viewport_config]),
      {RoboticaUi.Schedule, name: :ui_schedule},
      {RoboticaUi.Execute, name: :ui_execute},
      {RoboticaUi.RootManager, []}
    ]

    EventBus.subscribe({RoboticaUi.RoboticaService, ["^schedule", "^execute"]})
    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
