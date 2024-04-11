defmodule Search.Embeddings.Provider do
  alias Search.Embeddings

  @callback child_spec(config :: keyword()) :: atom() | {atom(), term()} | Supervisor.child_spec()

  @callback embed(progress_callback :: function(), config :: keyword()) :: [
              Embeddings.Embedding.t()
            ]

  @callback embed_one(text :: binary(), config :: keyword()) :: Nx.Tensor.t()
end
