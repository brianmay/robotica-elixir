defmodule RoboticaHello.Accounts.ErrorHandler do
  @moduledoc """
  Error handler for authentication errors
  """

  import Plug.Conn
  use RoboticaHelloWeb, :controller

  @behaviour Guardian.Plug.ErrorHandler

  @impl Guardian.Plug.ErrorHandler
  def auth_error(conn, {type, _reason}, _opts) do
    body = to_string(type)

    conn
    |> put_flash(:error, "Permission denied: #{body}")
    |> redirect(to: Routes.session_path(conn, :login))
  end
end
