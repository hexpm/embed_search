defmodule Search.Repo.Migrations.CreateFragments do
  use Ecto.Migration

  def change do
    create table(:fragments) do
      add :doc_text, :text
      add :embedding, :vector, size: Search.Embedding.embedding_size()

      timestamps(type: :utc_datetime)
    end
  end
end
