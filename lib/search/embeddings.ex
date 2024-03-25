defmodule Search.Embeddings do
  @moduledoc """
  The Embeddings context.
  """

  import Ecto.Query
  import Pgvector.Ecto.Query
  require Logger
  alias Search.Repo

  def knn_query(module, query_vector, opts \\ []) do
    %{metric: metric, k: k} =
      opts
      |> Keyword.validate!(metric: :cosine, k: nil)
      |> Map.new()

    query =
      from e in module,
        preload: [doc_fragment: [doc_item: :package]],
        select: e,
        limit: ^k

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
