defmodule Search.Embeddings.BumblebeeProvider do
  alias Search.Embeddings

  @behaviour Embeddings.Provider

  @impl true
  def child_spec(opts) do
    %{serving_name: serving_name} = parse_opts(opts)

    {Nx.Serving, serving: load_model(opts), name: serving_name, batch_size: get_batch_size(opts)}
  end

  @impl true
  def embed_one(text, opts) do
    %{serving_name: serving_name} = parse_opts(opts)

    Nx.Serving.batched_run(serving_name, text).embedding
  end

  @impl true
  def embed([] = _text_list, _progress_callback, _opts), do: []
  @impl true
  def embed(text_list, progress_callback, opts) do
    %{serving_name: serving_name} =
      parse_opts(opts)

    texts_count = length(text_list)

    batch_size =
      get_batch_size(opts)

    progress_callback.({texts_count, 0})

    text_list
    |> Stream.chunk_every(batch_size)
    |> Stream.with_index(1)
    |> Stream.map(fn {texts, batch_num} ->
      embeddings =
        Nx.Serving.batched_run(serving_name, texts)
        |> Enum.map(& &1.embedding)

      progress_callback.({texts_count, min(texts_count, batch_num * batch_size)})

      embeddings
    end)
    |> Enum.flat_map(&Function.identity/1)
  end

  defp get_batch_size(opts) do
    opts
    |> Keyword.fetch!(:serving_opts)
    |> Keyword.fetch!(:compile)
    |> Keyword.fetch!(:batch_size)
  end

  defp parse_opts(opts) do
    opts
    |> Keyword.validate!([
      :model,
      :serving_name,
      :embedding_size,
      :serving_opts,
      load_model_opts: [],
      load_tokenizer_opts: []
    ])
    |> Map.new()
  end

  defp load_model(opts) do
    %{
      serving_opts: serving_opts,
      model: model_repo,
      load_model_opts: load_model_opts,
      load_tokenizer_opts: load_tokenizer_opts
    } =
      parse_opts(opts)

    {:ok, model_info} = Bumblebee.load_model(model_repo, load_model_opts)

    {:ok, tokenizer} =
      Bumblebee.load_tokenizer(model_repo, load_tokenizer_opts)

    Bumblebee.Text.text_embedding(model_info, tokenizer, serving_opts)
  end
end
