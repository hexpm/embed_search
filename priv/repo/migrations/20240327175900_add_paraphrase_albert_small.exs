defmodule Search.Repo.Migrations.AddParaphraseAlbertSmall do
  require Search.MigrationHelper
  use Ecto.Migration

  def change do
    Search.MigrationHelper.change(Search.Embeddings.ParaphraseAlbertSmall)
  end
end
