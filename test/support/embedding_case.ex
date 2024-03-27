defmodule Search.EmbeddingCase do
  defmacro __using__(module) do
    quote do
      use Search.DataCase, async: true

      alias Search.{Repo, PackagesFixtures}

      setup ctx do
        case ctx do
          %{db: true} ->
            [fragment] = PackagesFixtures.doc_fragments_fixture(1)

            {:ok, %{fragment: fragment}}

          _ ->
            {:ok, []}
        end
      end

      test "creates embedding tensor of correct shape for a single input", _ctx do
        %{embedding: embedding} =
          Nx.Serving.batched_run(unquote(module), "The cat chases the mouse")

        assert Nx.shape(embedding) == {unquote(module).embedding_size()}
      end

      test "creates embedding tensor of correct shape for batched inputs", _ctx do
        [%{embedding: embedding1}, %{embedding: embedding2}] =
          Nx.Serving.batched_run(unquote(module), [
            "The cat chases the mouse",
            "Lorem ipsum dolor sit amet"
          ])

        assert Nx.shape(embedding1) == {unquote(module).embedding_size()}
        assert Nx.shape(embedding2) == {unquote(module).embedding_size()}
      end

      @tag :db
      test "can insert the embedding of the right size", %{fragment: fragment} do
        {embedding, _} =
          Nx.Random.uniform(Nx.Random.key(42), shape: {unquote(module).embedding_size()})

        assert {:ok, %unquote(module){} = _embedding_entity} =
                 Repo.insert(%unquote(module){
                   embedding: embedding,
                   doc_fragment: fragment
                 })
      end

      @tag :db
      test "cannot insert the embedding of the wrong size", %{fragment: fragment} do
        {embedding, _} =
          Nx.Random.uniform(Nx.Random.key(42), shape: {unquote(module).embedding_size() + 1})

        assert_raise Postgrex.Error, fn ->
          Repo.insert!(%unquote(module){
            embedding: embedding,
            doc_fragment: fragment
          })
        end
      end

      @tag :db
      test "cannot create an orphaned embedding", %{fragment: _fragment} do
        {embedding, _} =
          Nx.Random.uniform(Nx.Random.key(42), shape: {unquote(module).embedding_size() + 1})

        assert_raise Postgrex.Error, fn ->
          Repo.insert!(%unquote(module){
            embedding: embedding
          })
        end
      end

      @tag :db
      test "cannot create an embedding without the embedding tensor", %{fragment: fragment} do
        assert_raise Postgrex.Error, fn ->
          Repo.insert!(%unquote(module){
            doc_fragment: fragment
          })
        end
      end
    end
  end
end
