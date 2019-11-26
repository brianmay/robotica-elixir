defmodule RoboticaHello.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset
  @timestamps_opts [type: :utc_datetime, usec: true]

  schema "users" do
    field :email, :string
    field :is_admin, :boolean, default: false
    field :location, :string
    field :name, :string
    field :password, :string, virtual: true
    field :password_confirmation, :string, virtual: true
    field :password_hash, :string

    timestamps()
  end

  @doc false
  def create_changeset(user, attrs) do
    user
    |> cast(attrs, [:name, :email, :is_admin, :location, :password, :password_confirmation])
    |> validate_required([:name, :email, :location, :password, :password_confirmation])
    |> validate_length(:password, min: 8)
    |> validate_confirmation(:password)
    |> put_password_hash
    |> put_change(:password_confirmation, nil)
  end

  @doc false
  def update_changeset(user, attrs) do
    user
    |> cast(attrs, [:name, :email, :is_admin, :location])
    |> validate_required([:name, :email, :location])
  end

  @doc false
  def password_changeset(user, attrs) do
    user
    |> cast(attrs, [:password, :password_confirmation])
    |> validate_required([:password, :password_confirmation])
    |> validate_length(:password, min: 8)
    |> validate_confirmation(:password)
    |> put_password_hash
    |> put_change(:password_confirmation, nil)
  end

  defp put_password_hash(
         %Ecto.Changeset{valid?: true, changes: %{password: password}} = changeset
       ) do
    change(changeset, Bcrypt.add_hash(password))
  end

  defp put_password_hash(changeset), do: changeset
end
