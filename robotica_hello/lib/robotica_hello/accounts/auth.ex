defmodule RoboticaHello.Accounts.Auth do
  @moduledoc """
  Error handler if user in unauthorised
  """

  def unauthorized_response(conn) do
    conn
    |> Plug.Conn.put_resp_content_type("application/json")
    |> Plug.Conn.send_resp(401, ~s[{"message": "Unauthorized"}])
  end
end
