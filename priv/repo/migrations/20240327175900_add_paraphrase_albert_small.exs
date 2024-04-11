defmodule Search.Repo.Migrations.AddParaphraseAlbertSmall do
  use Ecto.Migration

  def change do
    create table("paraphrase_albert_small_embeddings") do
      add :embedding, :vector, size: 768, null: false
      add :doc_fragment_id, references("doc_fragments", on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end
  end
end
