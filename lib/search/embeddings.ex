defmodule Search.Embeddings do
  @moduledoc """
  The Embeddings context.
  """

  import Ecto.Query
  import Pgvector.Ecto.Query
  require Logger
  alias Search.{Embeddings, Repo, Packages}

  @doc """

  Embeds any doc fragments which do not have an embedding yet.

  Recieves an optional callback,
  which is called to notify about the embedding progress with the tuple {total, done} as its argument.
  """
  def embed(model_name, progress_callback \\ &Function.identity/1) do
    {provider, config} =
      Application.fetch_env!(:search, :embedding_providers)
      |> Keyword.fetch!(model_name)

    table_name = table_name(model_name)

    fragments =
      from f in Packages.DocFragment,
        left_join: e in ^{table_name, Embeddings.Embedding},
        on: e.doc_fragment_id == f.id,
        where: is_nil(e)

    fragments = Repo.all(fragments)
    texts = Enum.map(fragments, & &1.text)

    embeddings = provider.embed(texts, progress_callback, config)

    now = DateTime.utc_now(:second)

    embeddings_params =
      Stream.zip(fragments, embeddings)
      |> Enum.map(fn {fragment, embedding} ->
        %{
          doc_fragment_id: fragment.id,
          embedding: embedding,
          updated_at: now,
          inserted_at: now
        }
      end)

    Repo.transaction_with(fn ->
      {inserted_count, inserted_embeddings} =
        Repo.insert_all({table_name, Embeddings.Embedding}, embeddings_params, returning: true)

      if inserted_count == length(embeddings) do
        {:ok, inserted_embeddings}
      else
        {:error, "Could not insert all embeddings."}
      end
    end)
  end

  def embedding_size(model_name), do: get_config(model_name, :embedding_size)
  def table_name(model_name), do: "embeddings__#{model_name}"

  def embed_one(model_name, text) do
    {provider, config} =
      Application.fetch_env!(:search, :embedding_providers)
      |> Keyword.fetch!(model_name)

    provider.embed_one(text, config)
  end

  def knn_query(model_name, query_vector, opts \\ []) do
    table_name = table_name(model_name)

    %{metric: metric, k: k} =
      opts
      |> Keyword.validate!(metric: :cosine, k: nil)
      |> Map.new()

    query =
      from e in {table_name, Embeddings.Embedding},
        preload: [doc_fragment: [doc_item: :package]],
        select: e,
        limit: ^k

    query =
      case metric do
        :cosine ->
          from e in query,
            order_by: cosine_distance(e.embedding, ^query_vector)

        :l2 ->
          from e in query,
            order_by: l2_distance(e.embedding, ^query_vector)
      end

    Repo.all(query)
  end

  defp get_config(model_name, key) do
    {_provider, config} =
      Application.fetch_env!(:search, :embedding_providers)
      |> Keyword.fetch!(model_name)

    Keyword.fetch!(config, key)
  end
end
