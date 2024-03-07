defmodule Search.Repo.Migrations.CreateFragments do
  use Ecto.Migration

  def change do
    create table(:fragments) do
      add :doc_text, :text, null: false
      add :embedding, :vector, size: Search.Embedding.embedding_size(), null: false

      timestamps(type: :utc_datetime)
    end
  end
end
