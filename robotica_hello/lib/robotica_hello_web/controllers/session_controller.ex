defmodule RoboticaHelloWeb.SessionController do
  use RoboticaHelloWeb, :controller

  alias RoboticaHello.{Accounts, Accounts.Guardian, Accounts.User}
  alias RoboticaHelloWeb.Router.Helpers, as: Routes

  def new(conn, _) do
    changeset = Accounts.change_user(%User{})
    maybe_user = Guardian.Plug.current_resource(conn)

    if maybe_user do
      redirect(conn, to: Routes.page_path(conn, :index))
    else
      render(conn, "new.html", changeset: changeset, action: Routes.session_path(conn, :login))
    end
  end

  def login(conn, %{"user" => %{"username" => username, "password" => password}}) do
    Accounts.authenticate_user(username, password)
    |> login_reply(conn)
  end

  def logout(conn, _) do
    conn
    |> Guardian.Plug.sign_out()
    |> redirect(to: Routes.session_path(conn, :new))
  end

  defp login_reply({:ok, user}, conn) do
    conn
    |> put_flash(:info, "Welcome back!")
    |> Accounts.Guardian.Plug.sign_in(user)
    |> redirect(to: Routes.page_path(conn, :index))
  end

  defp login_reply({:error, reason}, conn) do
    conn
    |> put_flash(:error, to_string(reason))
    |> new(%{})
  end
end
