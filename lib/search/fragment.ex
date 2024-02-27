defmodule Search.Fragment do
  @moduledoc """
  Context for indexed documentation fragments - each fragment has associated with it an embedding vector, upon which
  kNN lookup can be performed.
  """

  alias Search.{Fragment, Repo}
  use Ecto.Schema
  import Ecto.{Changeset, Query}
  import Pgvector.Ecto.Query

  # Pgvector cannot handle inner product heuristic in ascending order, making it useless here
  @metrics [:cosine, :l2]

  schema "fragments" do
    field :doc_text, :string
    field :embedding, Pgvector.Ecto.Vector

    timestamps(type: :utc_datetime)
  end

  def metrics, do: @metrics

  def knn_lookup(query_tensor, opts \\ []) do
    opts = Keyword.validate!(opts, metric: :cosine, k: nil)
    metric = opts[:metric]
    k = opts[:k]

    query =
      case metric do
        :cosine ->
          from f in Fragment,
            order_by: cosine_distance(f.embedding, ^query_tensor),
            limit: ^k,
            select: f

        :l2 ->
          from f in Fragment,
            order_by: l2_distance(f.embedding, ^query_tensor),
            limit: ^k,
            select: f
      end

    Repo.all(query)
  end

  @doc false
  def changeset(fragment, attrs) do
    fragment
    |> cast(attrs, [:doc_text, :embedding])
    |> validate_required([:doc_text, :embedding])
  end
end
