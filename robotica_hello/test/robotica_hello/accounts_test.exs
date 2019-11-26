defmodule RoboticaHello.AccountsTest do
  use RoboticaHello.DataCase

  alias RoboticaHello.Accounts

  describe "users" do
    alias RoboticaHello.Accounts.User

    @valid_attrs %{email: "some email", location: "some location", is_admin: true, name: "some name", password: "some password", password_confirmation: "some password"}
    @update_attrs %{email: "some updated email", location: "some updated location", is_admin: false, name: "some updated name"}
    @invalid_attrs %{email: nil, location: nil, is_admin: nil, name: nil, password: nil}
    @password_attrs %{
      password: "some other password",
      password_confirmation: "some other password"
    }
    @invalid_password_attrs %{
      password: "some password",
      password_confirmation: "some other password"
    }

    def user_fixture(attrs \\ %{}) do
      {:ok, user} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Accounts.create_user()

      user
    end

    test "list_users/0 returns all users" do
      user = user_fixture()
      assert Accounts.list_users() == [user]
    end

    test "get_user!/1 returns the user with given id" do
      user = user_fixture()
      assert Accounts.get_user!(user.id) == user
    end

    test "create_user/1 with valid data creates a user" do
      assert {:ok, %User{} = user} = Accounts.create_user(@valid_attrs)
      assert user.email == "some email"
      assert user.location == "some location"
      assert user.is_admin == true
      assert user.name == "some name"
      {:ok, _} = Bcrypt.check_pass(user, "some password")
    end

    test "create_user/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Accounts.create_user(@invalid_attrs)
    end

    test "update_user/2 with valid data updates the user" do
      user = user_fixture()
      assert {:ok, %User{} = user} = Accounts.update_user(user, @update_attrs)
      assert user.email == "some updated email"
      assert user.location == "some updated location"
      assert user.is_admin == false
      assert user.name == "some updated name"
      {:ok, _} = Bcrypt.check_pass(user, "some password")
    end

    test "update_user/2 with invalid data returns error changeset" do
      user = user_fixture()
      assert {:error, %Ecto.Changeset{}} = Accounts.update_user(user, @invalid_attrs)
      assert user == Accounts.get_user!(user.id)
    end

    test "update_password/2 with valid data updates the user" do
      user = user_fixture()
      assert {:ok, %User{} = user} = Accounts.update_password(user, @password_attrs)
      {:ok, _} = Bcrypt.check_pass(user, "some other password")
    end

    test "update_password/2 with invalid data returns error changeset" do
      user = user_fixture()
      assert {:error, %Ecto.Changeset{}} = Accounts.update_password(user, @invalid_password_attrs)
      assert user == Accounts.get_user!(user.id)
      {:ok, _} = Bcrypt.check_pass(user, "some password")
    end

    test "delete_user/1 deletes the user" do
      user = user_fixture()
      assert {:ok, %User{}} = Accounts.delete_user(user)
      assert_raise Ecto.NoResultsError, fn -> Accounts.get_user!(user.id) end
    end

    test "change_user/1 returns a user changeset" do
      user = user_fixture()
      assert %Ecto.Changeset{} = Accounts.change_user(user)
    end

    test "change_password/1 returns a user changeset" do
      user = user_fixture()
      assert %Ecto.Changeset{} = Accounts.change_password(user)
    end

    test "authenticate_user/2 returns success" do
      user = user_fixture()
      {:ok, got_user} = Accounts.authenticate_user("some email", "some password")
      assert user == got_user
    end

    test "authenticate_user/2 with invalid username" do
      user_fixture()

      {:error, :invalid_credentials} = Accounts.authenticate_user("other email", "some password")
    end

    test "authenticate_user/2 with invalid password" do
      user_fixture()
      {:error, :invalid_credentials} = Accounts.authenticate_user("some email", "other password")
    end
  end
end
