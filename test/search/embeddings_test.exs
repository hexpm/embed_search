defmodule Search.EmbeddingsTest do
  use Search.DataCase, async: true

  alias Search.{Embeddings, Repo, PackagesFixtures}

  import Nx.Defn
  import Ecto.Query

  setup do
    {embeddings, rng_key} =
      Nx.Random.normal(Nx.Random.key(42), shape: {4, Embeddings.ParaphraseL3.embedding_size()})

    fragments = PackagesFixtures.doc_fragments_fixture(4)

    for {fragment, i} <- Enum.with_index(fragments) do
      Repo.insert!(%Embeddings.ParaphraseL3{doc_fragment: fragment, embedding: embeddings[i]})
    end

    {query, _} = Nx.Random.normal(rng_key, shape: {Embeddings.ParaphraseL3.embedding_size()})

    embeddings = Repo.all(from e in Embeddings.ParaphraseL3, select: e)

    {:ok, %{embeddings: embeddings, query: query}}
  end

  describe "knn_query/3" do
    test "when given no options, performs the kNN lookup on the entire repo using cosine distance",
         %{embeddings: embeddings, query: query} do
      knn_result = Embeddings.knn_query(Embeddings.ParaphraseL3, query)

      sorted_embeddings = sort_embeddings(embeddings, query, &manual_cosine_distance/2)

      assert Enum.map(knn_result, & &1.id) == Enum.map(sorted_embeddings, & &1.id)
    end

    test "when given [metric: :l2], performs the kNN lookup on the entire repo usin l2 distance",
         %{embeddings: embeddings, query: query} do
      knn_result = Embeddings.knn_query(Embeddings.ParaphraseL3, query, metric: :l2)

      sorted_embeddings = sort_embeddings(embeddings, query, &manual_l2_distance/2)

      assert Enum.map(knn_result, & &1.id) == Enum.map(sorted_embeddings, & &1.id)
    end

    test "when given value for :k option, returns only the top k results", %{query: query} do
      knn_result = Embeddings.knn_query(Embeddings.ParaphraseL3, query, k: 3)

      assert length(knn_result) == 3
    end
  end

  defp sort_embeddings(embeddings, query, dist_fn) do
    Enum.sort(embeddings, fn a, b ->
      Nx.to_number(dist_fn.(query, Pgvector.to_tensor(a.embedding))) <=
        Nx.to_number(dist_fn.(query, Pgvector.to_tensor(b.embedding)))
    end)
  end

  defnp manual_cosine_distance(a, b) do
    1 - Nx.dot(a, b) / Nx.sqrt(Nx.sum(Nx.pow(a, 2)) * Nx.sum(Nx.pow(b, 2)))
  end

  defnp manual_l2_distance(a, b) do
    Nx.sum(Nx.pow(a - b, 2))
  end
end
