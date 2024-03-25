defmodule Search.EmbeddingsTest.ParaphraseL3Test do
  use ExUnit.Case, async: true

  alias Search.Embeddings

  test "creates embedding tensor of correct shape for a single input" do
    %{embedding: embedding} =
      Nx.Serving.batched_run(Embeddings.ParaphraseL3, "The cat chases the mouse")

    assert Nx.shape(embedding) == {Embeddings.ParaphraseL3.embedding_size()}
  end

  test "creates embedding tensor of correct shape for batched inputs" do
    [%{embedding: embedding1}, %{embedding: embedding2}] =
      Nx.Serving.batched_run(Embeddings.ParaphraseL3, [
        "The cat chases the mouse",
        "Lorem ipsum dolor sit amet"
      ])

    assert Nx.shape(embedding1) == {Embeddings.ParaphraseL3.embedding_size()}
    assert Nx.shape(embedding2) == {Embeddings.ParaphraseL3.embedding_size()}
  end
end
