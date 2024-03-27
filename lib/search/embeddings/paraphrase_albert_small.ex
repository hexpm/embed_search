defmodule Search.Embeddings.ParaphraseAlbertSmall do
  alias Search.Embeddings

  use Embeddings.Embedding,
    model: {:hf, "sentence-transformers/paraphrase-albert-small-v2"},
    embedding_size: 768,
    serving_opts: [
      compile: [batch_size: 16, sequence_length: 100],
      defn_options: [compiler: EXLA]
    ]
end
