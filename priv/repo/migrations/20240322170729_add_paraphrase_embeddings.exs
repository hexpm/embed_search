defmodule Search.Repo.Migrations.AddParaphraseEmbeddings do
  require Search.MigrationHelper
  use Ecto.Migration

  def change do
    Search.MigrationHelper.change(Search.Embeddings.ParaphraseL3)
  end
end
