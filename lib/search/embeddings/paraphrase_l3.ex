defmodule Search.Embeddings.ParaphraseL3 do
  alias Search.Embeddings

  use Embeddings.Embedding,
    model: {:hf, "sentence-transformers/paraphrase-MiniLM-L3-v2"},
    embedding_size: 384,
    serving_opts: [
      compile: [batch_size: 16, sequence_length: 512],
      defn_options: [compiler: EXLA]
    ]
end
