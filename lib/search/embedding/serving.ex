defmodule Search.Embedding.Serving do
  alias Search.Embedding
  @behaviour Nx.Serving

  import Nx.Defn

  def child_spec(opts) do
    Nx.Serving.child_spec(Keyword.merge([serving: Nx.Serving.new(__MODULE__)], opts))
  end

  @impl true
  def init(_type, _arg, [defn_options]) do
    {model, params} = Embedding.model()
    predict_fn = jit(&generate_embedding/3, defn_options)
    {:ok, {model, params, predict_fn}}
  end

  @impl true
  def handle_batch(batch, 0, {model, params, predict_fn} = state) do
    {:execute, fn -> {predict_fn.(batch, model, params), :server_info} end, state}
  end

  defnp generate_embedding(batch, model, params) do
    Axon.predict(model, params, batch).pooled_state
  end
end
