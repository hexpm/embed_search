defmodule Search.Embeddings.BumblebeeProvider do
  alias Search.{Embeddings, Packages, Repo}
  import Ecto.Query

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
  def embed(progress_callback, opts) do
    %{table_name: table_name, serving_name: serving_name} =
      parse_opts(opts)

    fragments =
      from f in Packages.DocFragment,
        left_join: e in ^{table_name, Embeddings.Embedding},
        on: e.doc_fragment_id == f.id,
        where: is_nil(e)

    fragments = Repo.all(fragments)

    if fragments == [] do
      {:ok, []}
    else
      fragments_count = length(fragments)

      batch_size =
        get_batch_size(opts)

      fragment_texts =
        fragments
        |> Stream.map(& &1.text)
        |> Stream.chunk_every(batch_size)

      embeddings =
        fragment_texts
        |> Stream.with_index(1)
        |> Stream.flat_map(fn {texts, index} ->
          embeddings = Nx.Serving.batched_run(serving_name, texts)

          progress_callback.({fragments_count, min(index * batch_size, fragments_count)})

          Stream.map(embeddings, & &1.embedding)
        end)

      progress_callback.({fragments_count, 0})

      now = DateTime.utc_now(:second)

      embeddings_params =
        [fragments, embeddings]
        |> Stream.zip()
        |> Enum.map(fn {fragment, embedding} ->
          %{
            embedding: embedding,
            doc_fragment_id: fragment.id,
            inserted_at: now,
            updated_at: now
          }
        end)

      Repo.transaction(fn ->
        {inserted, embeddings} =
          Repo.insert_all(
            {table_name, Embeddings.Embedding},
            embeddings_params,
            returning: true
          )

        if inserted == fragments_count do
          embeddings
        else
          Repo.rollback("Could not insert all embeddings")
        end
      end)
    end
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
      :table_name,
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
