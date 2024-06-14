defmodule Search.EmbeddingsTest do
  use Search.DataCase, async: true

  alias Search.{Embeddings, Repo, PackagesFixtures}

  import Nx.Defn
  import Ecto.Query

  setup do
    {_, config} =
      Application.fetch_env!(:search, :embedding_providers) |> Keyword.fetch!(:paraphrase_l3)

    %{embedding_size: embedding_size} =
      Map.new(config)

    table_name = Embeddings.table_name(:paraphrase_l3)

    {embeddings, rng_key} =
      Nx.Random.normal(Nx.Random.key(42), shape: {4, embedding_size})

    fragments = PackagesFixtures.doc_fragments_fixture(4)

    now = DateTime.utc_now(:second)

    embeddings =
      for {fragment, i} <- Enum.with_index(fragments) do
        %{
          doc_fragment_id: fragment.id,
          embedding: embeddings[i],
          inserted_at: now,
          updated_at: now
        }
      end

    Repo.insert_all({table_name, Embeddings.Embedding}, embeddings)

    {query, _} = Nx.Random.normal(rng_key, shape: {embedding_size})

    embeddings = Repo.all(from e in {table_name, Embeddings.Embedding}, select: e)

    {:ok, %{embeddings: embeddings, query: query, fragments: Repo.reload!(fragments)}}
  end

  describe "embed_one/2" do
    test "creates embedding tensor of correct shape for a single input", _ctx do
      embedding =
        Embeddings.embed_one(:paraphrase_l3, "The cat chases the mouse")

      assert Nx.shape(embedding) == {Embeddings.embedding_size(:paraphrase_l3)}
    end

    test "fails for nonexistent model", _ctx do
      assert_raise KeyError, fn ->
        Embeddings.embed_one(:no_such_model, "The cat chases the mouse")
      end
    end
  end

  describe "embed" do
    test "creates an embedding entity for each fragment to be embedded", %{
      fragments: fragments
    } do
      {:ok, new_embeddings} = Embeddings.embed(:paraphrase_albert_small)

      embeddings_num = Repo.aggregate(Embeddings.table_name(:paraphrase_albert_small), :count)

      assert embeddings_num == length(fragments)
      assert length(new_embeddings) == length(fragments)
    end

    test "calls the progress callback if provided", %{
      fragments: fragments
    } do
      self_pid = self()
      callback = fn arg -> send(self_pid, arg) end

      {:ok, _} = Embeddings.embed(:paraphrase_albert_small, callback)

      fragments_count = length(fragments)

      assert_received {^fragments_count, done} when is_integer(done)
    end

    test "does no work for already embedded fragments", _ctx do
      self_pid = self()
      callback = fn _ -> send(self_pid, :never_receive) end

      assert {:ok, []} = Embeddings.embed(:paraphrase_l3, callback)

      refute_received :never_receive
    end
  end

  describe "knn_query/3" do
    test "when given no options, performs the kNN lookup on the entire repo using cosine distance",
         %{embeddings: embeddings, query: query} do
      knn_result = Embeddings.knn_query(:paraphrase_l3, query)

      sorted_embeddings = sort_embeddings(embeddings, query, &manual_cosine_distance/2)

      assert Enum.map(knn_result, & &1.id) == Enum.map(sorted_embeddings, & &1.id)
    end

    test "when given [metric: :l2], performs the kNN lookup on the entire repo usin l2 distance",
         %{embeddings: embeddings, query: query} do
      knn_result = Embeddings.knn_query(:paraphrase_l3, query, metric: :l2)

      sorted_embeddings = sort_embeddings(embeddings, query, &manual_l2_distance/2)

      assert Enum.map(knn_result, & &1.id) == Enum.map(sorted_embeddings, & &1.id)
    end

    test "when given value for :k option, returns only the top k results", %{query: query} do
      knn_result = Embeddings.knn_query(:paraphrase_l3, query, k: 3)

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
