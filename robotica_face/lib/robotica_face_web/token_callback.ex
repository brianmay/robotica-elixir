defmodule RoboticaFaceWeb.TokenCallback do
  @moduledoc """
  Callback from Plugoid to set session details from token
  """
  import Plug.Conn

  @spec callback(
          Plug.Conn.t(),
          OIDC.Auth.OPResponseSuccess.t(),
          String.t(),
          String.t(),
          keyword()
        ) :: Plug.Conn.t()
  def callback(conn, response, _issuer, _client_id, _opts) do
    sub = response.id_token_claims["sub"]
    claims = Map.take(response.id_token_claims, ["groups", "name", "sub"])

    conn
    |> fetch_session()
    |> put_session(:live_socket_id, "users_socket:#{sub}")
    |> put_session(:claims, claims)
  end
end
