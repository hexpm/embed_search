defmodule Search.Repo.Migrations.CreateSchema do
  use Ecto.Migration

  def change do
    execute "CREATE EXTENSION IF NOT EXISTS vector", "DROP EXTENSION vector"

    create table(:packages) do
      add :name, :string, null: false
      add :version, :string, null: false

      timestamps(type: :utc_datetime)
    end

    create table(:doc_items) do
      add :ref, :string, null: false
      add :type, :string, null: false
      add :title, :string, null: false
      add :doc, :text
      add :package_id, references("packages", on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create table(:doc_fragments) do
      add :text, :text, null: false
      add :doc_item_id, references("doc_items", on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create table(:paraphrase_l3_embeddings) do
      add :embedding, :vector, size: 384, null: false
      add :doc_fragment_id, references("doc_fragments", on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create table(:paraphrase_albert_small_embeddings) do
      add :embedding, :vector, size: 768, null: false
      add :doc_fragment_id, references("doc_fragments", on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end
  end
end
