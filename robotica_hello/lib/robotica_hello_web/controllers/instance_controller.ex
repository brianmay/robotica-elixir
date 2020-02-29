defmodule RoboticaHelloWeb.InstanceController do
  use RoboticaHelloWeb, :controller

  def index(conn, _params) do
    config = RoboticaHello.Config.ui_configuration()
    render(conn, "index.html", instances: config.instances)
  end
end
