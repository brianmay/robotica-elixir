defmodule RoboticaHelloWeb.InstanceController do
  use RoboticaHelloWeb, :controller

  def index(conn, _params) do
    config = RoboticaHello.Config.ui_configuration()
    IO.inspect(config.instances)
    render(conn, "index.html", instances: config.instances)
  end
end
