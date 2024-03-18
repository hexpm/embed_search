defmodule Search.Repo.Migrations.CreateDocFragments do
  use Ecto.Migration

  def change do
    create table(:doc_fragments) do
      add :text, :text, null: false
      add :doc_item_id, references("doc_items", on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end
  end
end
