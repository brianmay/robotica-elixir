defmodule RoboticaHello.Accounts.User do
  @moduledoc """
  Actions for users
  """
  use Ecto.Schema
  import Ecto.Changeset
  @timestamps_opts [type: :utc_datetime, usec: true]

  @type t :: %__MODULE__{
          username: String.t() | nil,
          is_admin: boolean() | nil,
          name: String.t() | nil,
          password: String.t() | nil,
          password_confirmation: String.t() | nil,
          password_hash: String.t() | nil,
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  schema "users" do
    field :username, :string
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
    |> cast(attrs, [:name, :username, :is_admin, :location, :password, :password_confirmation])
    |> validate_required([:name, :username, :location, :password, :password_confirmation])
    |> validate_length(:password, min: 8)
    |> validate_confirmation(:password)
    |> put_password_hash
    |> put_change(:password_confirmation, nil)
  end

  @doc false
  def update_changeset(user, attrs) do
    user
    |> cast(attrs, [:name, :username, :is_admin, :location])
    |> validate_required([:name, :username, :location])
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
