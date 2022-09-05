defmodule RoboticaUi.Assets do
  @moduledoc """
  Assets for the RoboticaUi application
  """
  use Scenic.Assets.Static,
    otp_app: :robotica_ui,
    alias: [
      local: "images/local.png",
      remote: "images/remote.png",
      schedule: "images/schedule.png"
    ]
end
