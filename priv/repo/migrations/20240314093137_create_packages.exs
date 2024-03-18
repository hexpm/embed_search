defmodule Search.Repo.Migrations.CreatePackages do
  use Ecto.Migration

  def change do
    create table(:packages) do
      add :name, :string, null: false
      add :version, :string, null: false

      timestamps(type: :utc_datetime)
    end
  end
end
