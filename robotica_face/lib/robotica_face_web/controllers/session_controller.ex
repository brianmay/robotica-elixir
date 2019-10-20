defmodule RoboticaFaceWeb.SessionController do
  use RoboticaFaceWeb, :controller

  alias RoboticaFace.Auth
  alias RoboticaFaceWeb.Router.Helpers, as: Routes

  def index(conn, _params) do
    maybe_user = Auth.current_user(conn)

    message =
      if maybe_user != nil do
        "Someone is logged in"
      else
        "No one is logged in"
      end

    conn
    |> put_flash(:info, message)
    |> render("index.html",
      action: Routes.session_path(conn, :login),
      maybe_user: maybe_user
    )
  end

  def login(conn, %{"token" => token}) do
    Auth.authenticate_user(token)
    |> login_reply(conn)
  end

  defp login_reply({:error, error}, conn) do
    conn
    |> put_flash(:error, error)
    |> redirect(to: Routes.session_path(conn, :index))
  end

  defp login_reply({:ok, user}, conn) do
    conn
    |> put_flash(:success, "Welcome back!")
    |> Auth.login(user)
    |> redirect(to: "/")
  end

  def logout(conn, _) do
    conn
    |> Auth.logout()
    |> redirect(to: Routes.session_path(conn, :login))
  end
end
