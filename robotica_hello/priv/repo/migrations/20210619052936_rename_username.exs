defmodule RoboticaHello.Repo.Migrations.RenameUsername do
  use Ecto.Migration

  def change do
    rename table(:users), :email, to: :username
  end
end
