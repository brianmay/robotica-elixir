defmodule RoboticaHelloWeb.PageController do
  use RoboticaHelloWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html", active: "index")
  end
end
