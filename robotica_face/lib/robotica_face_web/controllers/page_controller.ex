defmodule RoboticaFaceWeb.PageController do
  use RoboticaFaceWeb, :controller

  @spec index(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def index(conn, _params) do
    render(conn, "index.html", active: "index")
  end

  @spec logout(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def logout(conn, _params) do
    user = RoboticaFaceWeb.Auth.current_user(conn)

    if user != nil do
      sub = user["sub"]
      RoboticaFaceWeb.Endpoint.broadcast("users_socket:#{sub}", "disconnect", %{})
    end

    conn
    |> Plugoid.logout()
    |> put_session(:claims, nil)
    |> put_flash(:danger, "You are now logged out.")
    |> redirect(to: Routes.page_path(conn, :index))
  end

  @spec login(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def login(conn, _params) do
    redirect(conn, to: Routes.page_path(conn, :index))
  end
end
