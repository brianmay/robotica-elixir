defmodule RoboticaFaceWeb.PageController do
  use RoboticaFaceWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end

  def local(conn, _params) do
    render(conn, "local.html")
  end

  def remote(conn, _params) do
    render(conn, "remote.html")
  end

  def schedule(conn, _params) do
    render(conn, "schedule.html")
  end
end
