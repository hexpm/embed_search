defmodule Search.Embeddings.Embedding do
  @type t :: %__MODULE__{}

  use Ecto.Schema
  import Ecto.Changeset
  alias Pgvector.Ecto.Vector
  alias Search.Packages

  schema "" do
    field :embedding, Vector
    belongs_to :doc_fragment, Packages.DocFragment

    timestamps(type: :utc_datetime)
  end

  def changeset(embedding, attrs) do
    embedding
    |> cast(attrs, [:embedding])
    |> cast_assoc(:doc_fragment, required: true)
    |> validate_required([:embedding])
  end
end
