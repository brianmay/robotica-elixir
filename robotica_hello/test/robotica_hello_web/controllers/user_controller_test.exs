defmodule RoboticaHelloWeb.UserControllerTest do
  use RoboticaHelloWeb.ConnCase

  alias RoboticaHello.Accounts
  alias RoboticaHello.Accounts.Guardian

  @create_attrs %{
    username: "some username",
    location: "some location",
    is_admin: true,
    name: "some name",
    password: "some password",
    password_confirmation: "some password"
  }
  @update_attrs %{
    username: "some updated username",
    location: "some updated location",
    is_admin: false,
    name: "some updated name"
  }
  @invalid_attrs %{username: nil, location: nil, name: nil, is_admin: nil, password: nil}
  @password_attrs %{
    password: "some password",
    password_confirmation: "some password"
  }
  @invalid_password_attrs %{
    password: "some password",
    password_confirmation: "some other password"
  }

  def fixture(:token) do
    {:ok, user} =
      Accounts.create_user(%{
        name: "User",
        location: "location",
        is_admin: false,
        password: "some password",
        password_confirmation: "some password",
        username: "user"
      })

    {:ok, token, _} = Guardian.encode_and_sign(user, %{}, token_type: :access)
    token
  end

  def fixture(:admin_token) do
    {:ok, user} =
      Accounts.create_user(%{
        name: "Admin",
        location: "location",
        is_admin: true,
        password: "some password",
        password_confirmation: "some password",
        username: "admin"
      })

    {:ok, token, _} = Guardian.encode_and_sign(user, %{}, token_type: :access)
    token
  end

  def fixture(:user) do
    {:ok, user} = Accounts.create_user(@create_attrs)
    user
  end

  describe "non admin user" do
    setup [:create_user]

    test "lists all users", %{conn: conn} do
      token = fixture(:token)
      conn = put_req_header(conn, "authorization", "bearer: " <> token)
      conn = get(conn, Routes.user_path(conn, :index))
      response(conn, 401)
    end

    test "new user", %{conn: conn} do
      token = fixture(:token)
      conn = put_req_header(conn, "authorization", "bearer: " <> token)
      conn = get(conn, Routes.user_path(conn, :new))
      response(conn, 401)
    end

    test "create user", %{conn: conn} do
      token = fixture(:token)
      conn = put_req_header(conn, "authorization", "bearer: " <> token)
      conn = put(conn, Routes.user_path(conn, :new))
      response(conn, 401)
    end

    test "edit user", %{conn: conn, user: user} do
      token = fixture(:token)
      conn = put_req_header(conn, "authorization", "bearer: " <> token)
      conn = get(conn, Routes.user_path(conn, :edit, user))
      response(conn, 401)
    end

    test "update user", %{conn: conn, user: user} do
      token = fixture(:token)
      conn = put_req_header(conn, "authorization", "bearer: " <> token)
      conn = put(conn, Routes.user_path(conn, :update, user))
      response(conn, 401)
    end

    test "edit user password", %{conn: conn, user: user} do
      token = fixture(:token)
      conn = put_req_header(conn, "authorization", "bearer: " <> token)
      conn = get(conn, Routes.user_path(conn, :password_edit, user))
      response(conn, 401)
    end

    test "update user password", %{conn: conn, user: user} do
      token = fixture(:token)
      conn = put_req_header(conn, "authorization", "bearer: " <> token)
      conn = put(conn, Routes.user_path(conn, :password_update, user))
      response(conn, 401)
    end

    test "show user", %{conn: conn, user: user} do
      token = fixture(:token)
      conn = put_req_header(conn, "authorization", "bearer: " <> token)
      conn = get(conn, Routes.user_path(conn, :edit, user))
      response(conn, 401)
    end

    test "delete user", %{conn: conn, user: user} do
      token = fixture(:token)
      conn = put_req_header(conn, "authorization", "bearer: " <> token)
      conn = delete(conn, Routes.user_path(conn, :delete, user))
      response(conn, 401)
    end
  end

  describe "index" do
    test "lists all users", %{conn: conn} do
      token = fixture(:admin_token)
      conn = put_req_header(conn, "authorization", "bearer: " <> token)

      conn = get(conn, Routes.user_path(conn, :index))
      assert html_response(conn, 200) =~ "Listing Users"
    end
  end

  describe "new user" do
    test "renders form", %{conn: conn} do
      token = fixture(:admin_token)
      conn = put_req_header(conn, "authorization", "bearer: " <> token)

      conn = get(conn, Routes.user_path(conn, :new))
      assert html_response(conn, 200) =~ "New User"
    end
  end

  describe "create user" do
    test "redirects to show when data is valid", %{conn: conn} do
      token = fixture(:admin_token)
      conn = put_req_header(conn, "authorization", "bearer: " <> token)

      conn = post(conn, Routes.user_path(conn, :create), user: @create_attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == Routes.user_path(conn, :show, id)

      conn = get(conn, Routes.user_path(conn, :show, id))
      assert html_response(conn, 200) =~ "Show User"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      token = fixture(:admin_token)
      conn = put_req_header(conn, "authorization", "bearer: " <> token)

      conn = post(conn, Routes.user_path(conn, :create), user: @invalid_attrs)
      assert html_response(conn, 200) =~ "New User"
    end
  end

  describe "edit user" do
    setup [:create_user]

    test "renders form for editing chosen user", %{conn: conn, user: user} do
      token = fixture(:admin_token)
      conn = put_req_header(conn, "authorization", "bearer: " <> token)

      conn = get(conn, Routes.user_path(conn, :edit, user))
      assert html_response(conn, 200) =~ "Edit User"
    end
  end

  describe "update user" do
    setup [:create_user]

    test "redirects when data is valid", %{conn: conn, user: user} do
      token = fixture(:admin_token)
      conn = put_req_header(conn, "authorization", "bearer: " <> token)

      conn = put(conn, Routes.user_path(conn, :update, user), user: @update_attrs)
      assert redirected_to(conn) == Routes.user_path(conn, :show, user)

      conn = get(conn, Routes.user_path(conn, :show, user))
      assert html_response(conn, 200) =~ "some updated username"
    end

    test "renders errors when data is invalid", %{conn: conn, user: user} do
      token = fixture(:admin_token)
      conn = put_req_header(conn, "authorization", "bearer: " <> token)

      conn = put(conn, Routes.user_path(conn, :update, user), user: @invalid_attrs)
      assert html_response(conn, 200) =~ "Edit User"
    end
  end

  describe "update password" do
    setup [:create_user]

    test "redirects when data is valid", %{conn: conn, user: user} do
      token = fixture(:admin_token)
      conn = put_req_header(conn, "authorization", "bearer: " <> token)

      conn = put(conn, Routes.user_path(conn, :password_update, user), user: @password_attrs)
      assert redirected_to(conn) == Routes.user_path(conn, :show, user)

      conn = get(conn, Routes.user_path(conn, :show, user))
      assert html_response(conn, 200) =~ "Show User"
    end

    test "renders errors when data is invalid", %{conn: conn, user: user} do
      token = fixture(:admin_token)
      conn = put_req_header(conn, "authorization", "bearer: " <> token)

      conn =
        put(conn, Routes.user_path(conn, :password_update, user), user: @invalid_password_attrs)

      assert html_response(conn, 200) =~ "Change User Password"
    end
  end

  describe "delete user" do
    setup [:create_user]

    test "deletes chosen user", %{conn: conn, user: user} do
      token = fixture(:admin_token)
      conn = put_req_header(conn, "authorization", "bearer: " <> token)

      conn = delete(conn, Routes.user_path(conn, :delete, user))
      assert redirected_to(conn) == Routes.user_path(conn, :index)

      assert_error_sent 404, fn ->
        get(conn, Routes.user_path(conn, :show, user))
      end
    end
  end

  defp create_user(_) do
    user = fixture(:user)
    {:ok, user: user}
  end
end
