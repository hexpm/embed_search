defmodule Search.Embeddings do
  @moduledoc """
  The Embeddings context.
  """

  import Ecto.Query
  import Pgvector.Ecto.Query
  require Logger
  alias Search.Embeddings
  alias Search.Repo

  @doc """

  Embeds any doc fragments which do not have an embedding yet.

  Recieves an optional callback,
  which is called to notify about the embedding progress with the tuple {total, done} as its argument.
  """
  def embed(model_name, progress_callback \\ &Function.identity/1) do
    {provider, config} =
      Application.fetch_env!(:search, :embedding_providers)
      |> Keyword.fetch!(model_name)

    provider.embed(progress_callback, config)
  end

  def embedding_size(model_name), do: get_config(model_name, :embedding_size)
  def table_name(model_name), do: get_config(model_name, :table_name)

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
