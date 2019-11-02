defmodule RoboticaFaceWeb.PageController do
  use RoboticaFaceWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html", active: "index")
  end

  def local(conn, _params) do
    render(conn, "local.html", active: "local")
  end

  def remote(conn, _params) do
    render(conn, "remote.html", active: "remote")
  end

  def schedule(conn, _params) do
    render(conn, "schedule.html", active: "schedule")
  end

  def tesla(conn, _params) do
    render(conn, "tesla.html", active: "tesla")
  end
end
