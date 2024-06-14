defmodule Search.Embeddings.Provider do
  @callback child_spec(config :: keyword()) :: atom() | {atom(), term()} | Supervisor.child_spec()

  @callback embed(
              stream :: [String.t()],
              progress_callback :: ({total :: integer(), done :: integer()} -> any()),
              config :: keyword()
            ) ::
              [Nx.Tensor.t()]

  @callback embed_one(text :: binary(), config :: keyword()) :: Nx.Tensor.t()
end
