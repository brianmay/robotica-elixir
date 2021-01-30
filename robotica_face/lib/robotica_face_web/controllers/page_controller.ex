defmodule RoboticaFaceWeb.PageController do
  use RoboticaFaceWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html", active: "index")
  end

  def local(conn, _params) do
    render(conn, "local.html", active: "local")
  end

  def schedule(conn, _params) do
    render(conn, "schedule.html", active: "schedule")
  end
end
