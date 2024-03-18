defmodule Search.Repo.Migrations.CreateDocItems do
  use Ecto.Migration

  def change do
    create table(:doc_items) do
      add :ref, :string, null: false
      add :type, :string, null: false
      add :title, :string, null: false
      add :doc, :text
      add :package_id, references("packages", on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end
  end
end
