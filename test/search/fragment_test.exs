defmodule Search.FragmentTest do
  use Search.DataCase, async: true

  alias Search.{Fragment, Embedding}

  import Nx.Defn

  setup do
    {embeddings, rng_key} =
      Nx.Random.normal(Nx.Random.key(42), shape: {10, Embedding.embedding_size()})

    for i <- 0..9 do
      Repo.insert!(%Fragment{doc_text: "Text #{i}", embedding: embeddings[i]})
    end

    {query, _} = Nx.Random.normal(rng_key, shape: {Embedding.embedding_size()})

    fragments = Repo.all(from f in Fragment, select: f)

    {:ok, %{fragments: fragments, query: query}}
  end

  describe "knn_query/2" do
    test "when given no options, performs the kNN lookup on the entire repo using cosine distance",
         %{fragments: fragments, query: query} do
      knn_result = Fragment.knn_lookup(query)

      sorted_fragments = sort_fragments(fragments, query, &manual_cosine_distance/2)

      assert Enum.map(knn_result, & &1.id) == Enum.map(sorted_fragments, & &1.id)
    end

    test "when given [metric: :l2], performs the kNN lookup on the entire repo usin l2 distance",
         %{fragments: fragments, query: query} do
      knn_result = Fragment.knn_lookup(query, metric: :l2)

      sorted_fragments = sort_fragments(fragments, query, &manual_l2_distance/2)

      assert Enum.map(knn_result, & &1.id) == Enum.map(sorted_fragments, & &1.id)
    end

    test "when given value for :k option, returns only the top k results", %{query: query} do
      knn_result = Fragment.knn_lookup(query, k: 5)

      assert length(knn_result) == 5
    end
  end

  defp sort_fragments(fragments, query, dist_fn) do
    Enum.sort(fragments, fn a, b ->
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
