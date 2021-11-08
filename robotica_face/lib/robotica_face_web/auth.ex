defmodule RoboticaFaceWeb.Auth do
  @moduledoc """
  Helper functions for authorization
  """

  @spec current_user(Plug.Conn.t()) :: map()
  def current_user(conn) do
    Plug.Conn.get_session(conn, :claims)
  end

  @spec user_is_admin?(map()) :: boolean()
  def user_is_admin?(user) do
    case user do
      %{"groups" => groups} -> Enum.member?(groups, "admin")
      _ -> false
    end
  end
end
