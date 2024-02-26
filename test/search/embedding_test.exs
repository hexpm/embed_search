defmodule Search.EmbeddingTest do
  use ExUnit.Case, async: true

  require Nx
  require Logger
  alias Search.Embedding

  test "creates embedding tensor of correct shape for a single input" do
    %{embedding: embedding} = Nx.Serving.batched_run(Search.Embedding, "The cat chases the mouse")

    assert {Embedding.embedding_size()} == Nx.shape(embedding)
  end

  test "creates embedding tensor of correct shape for batched inputs" do
    [%{embedding: embedding1}, %{embedding: embedding2}] =
      Nx.Serving.batched_run(Search.Embedding, [
        "The cat chases the mouse",
        "Lorem ipsum dolor sit amet"
      ])

    assert {Embedding.embedding_size()} == Nx.shape(embedding1)
    assert {Embedding.embedding_size()} == Nx.shape(embedding2)
  end
end
