defmodule RoboticaHelloWeb.InstanceController do
  use RoboticaHelloWeb, :controller

  def index(conn, _params) do
    config = RoboticaHello.Config.configuration()
    render(conn, "index.html", instances: config.instances)
  end
end
