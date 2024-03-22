defmodule Search.Embeddings do
  @moduledoc """
  The Embeddings context.
  """

  import Ecto.Query
  import Pgvector.Ecto.Query
  alias Search.Repo

  def knn_query(module, query_vector, opts \\ []) do
    opts = Keyword.validate!(opts, metric: :cosine, k: nil)
    metric = opts[:metric]
    k = opts[:k]

    query =
      from e in module,
        preload: [doc_fragments: [doc_items: :packages]],
        limit: ^k,
        select: e

    query =
      case metric do
        :cosine ->
          from e in query,
            order_by: cosine_distance(e.embedding, ^query_vector)

        :l2 ->
          from e in query,
            order_by: l2_distance(e.embedding, ^query_vector)
      end

    Repo.all(query)
  end
end
