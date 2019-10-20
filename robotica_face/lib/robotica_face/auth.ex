defmodule RoboticaFace.Auth do
  import Plug.Conn

  def authenticate_user(token) do
    case RoboticaFace.Token.verify_and_validate(token) do
      {:ok, user} -> {:ok, {token, user}}
      {:error, error} -> {:error, "Invalid token: #{inspect(error)}"}
    end
  end

  def login(conn, {token, user}) do
    conn
    |> put_session(:token, token)
    |> assign(:user, user)
  end

  def logout(conn) do
    conn
    |> put_session(:token, nil)
    |> assign(:user, nil)
  end

  def current_user(conn) do
    conn.assigns[:user]
  end

  def user_signed_in?(conn) do
    !!current_user(conn)
  end

  defmodule CheckLoginToken do
    import Plug.Conn

    def init(default), do: default

    def call(conn, _default) do
      case get_session(conn, :token) do
        nil ->
          RoboticaFace.Auth.logout(conn)

        token ->
          case RoboticaFace.Auth.authenticate_user(token) do
            {:ok, user} -> RoboticaFace.Auth.login(conn, user)
            {:error, _} -> RoboticaFace.Auth.logout(conn)
          end
      end
    end
  end

  defmodule EnsureAuth do
    def init(default), do: default

    def call(conn, _default) do
      case RoboticaFace.Auth.user_signed_in?(conn) do
        false -> Phoenix.Controller.redirect(conn, to: "/")
        true -> conn
      end
    end
  end
end
