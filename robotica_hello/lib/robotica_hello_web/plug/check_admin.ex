defmodule RoboticaHelloWeb.Plug.CheckAdmin do
  @moduledoc "Plugin to check if user is admin"
  import Plug.Conn

  use RoboticaHelloWeb, :controller

  def init(_params) do
  end

  def call(conn, _params) do
    user = Guardian.Plug.current_resource(conn)

    if user.is_admin do
      conn
    else
      conn
      |> put_flash(:danger, "Permission denied: Not authorized")
      |> redirect(to: Routes.session_path(conn, :login, next: conn.request_path))
      |> halt()
    end
  end
end
