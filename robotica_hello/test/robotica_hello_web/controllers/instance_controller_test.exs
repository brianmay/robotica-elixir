defmodule RoboticaHelloWeb.InstanceControllerTest do
  use RoboticaHelloWeb.ConnCase

  alias RoboticaHello.Accounts
  alias RoboticaHello.Accounts.Guardian

  def fixture(:user) do
    {:ok, user} =
      Accounts.create_user(%{
        name: "Test User",
        location: "Brian",
        is_admin: false,
        password: "some password",
        password_confirmation: "some password",
        email: "user"
      })

    user
  end

  def fixture(:token) do
    user = fixture(:user)
    {:ok, token, _} = Guardian.encode_and_sign(user, %{}, token_type: :access)
    token
  end

  describe "anonymous access" do
    test "show instances", %{conn: conn} do
      conn = get(conn, Routes.instance_path(conn, :index))
      response(conn, 302)
    end
  end

  describe "authenticated access" do
    test "show instances", %{conn: conn} do
      token = fixture(:token)
      conn = put_req_header(conn, "authorization", "bearer: " <> token)
      conn = get(conn, Routes.instance_path(conn, :index))
      response(conn, 200)
    end
  end
end
