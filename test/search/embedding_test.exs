defmodule Search.EmbeddingTest do
  use ExUnit.Case, async: true

  alias Search.Embedding

  test "creates embedding tensor of correct shape for a single input" do
    %{embedding: embedding} = Nx.Serving.batched_run(Embedding, "The cat chases the mouse")

    assert Nx.shape(embedding) == {Embedding.embedding_size()}
  end

  test "creates embedding tensor of correct shape for batched inputs" do
    [%{embedding: embedding1}, %{embedding: embedding2}] =
      Nx.Serving.batched_run(Embedding, [
        "The cat chases the mouse",
        "Lorem ipsum dolor sit amet"
      ])

    assert Nx.shape(embedding1) == {Embedding.embedding_size()}
    assert Nx.shape(embedding2) == {Embedding.embedding_size()}
  end
end
