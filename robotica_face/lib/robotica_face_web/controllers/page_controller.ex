defmodule RoboticaFaceWeb.PageController do
  use RoboticaFaceWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
