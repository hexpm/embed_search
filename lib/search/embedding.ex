defmodule Search.Embedding do
  @embedding_size 384
  @model_repo {:hf, "sentence-transformers/paraphrase-MiniLM-L3-v2"}

  require Logger

  def embedding_size, do: @embedding_size

  def child_spec(opts) do
    opts
    |> Keyword.merge(serving: load_model())
    |> Nx.Serving.child_spec()
  end

  defp load_model() do
    {:ok, model_info} = Bumblebee.load_model(@model_repo)
    {:ok, tokenizer} = Bumblebee.load_tokenizer(@model_repo)

    Bumblebee.Text.text_embedding(model_info, tokenizer)
  end
end
