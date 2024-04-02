defmodule Search.Embeddings.Embedding do
  defmacro __using__(opts \\ []) do
    %{
      model: model_repo,
      embedding_size: embedding_size,
      serving_opts: serving_opts,
      load_model_opts: load_model_opts,
      load_tokenizer_opts: load_tokenizer_opts
    } =
      opts
      |> Keyword.validate!([
        :model,
        :embedding_size,
        serving_opts: [],
        load_model_opts: [],
        load_tokenizer_opts: []
      ])
      |> Map.new()

    batch_size =
      serving_opts
      |> Keyword.get(:compile, [])
      |> Keyword.get(:batch_size)

    table_name =
      quote do
        "#{Macro.underscore(__MODULE__)}_embeddings"
      end

    text_batching =
      if batch_size do
        quote do
          Stream.map(& &1.text)
          |> Stream.chunk_every(unquote(batch_size))
        end
      else
        quote do
          Stream.map(& &1.text)
        end
      end

    quote do
      alias Search.{Packages, Repo}
      use Ecto.Schema
      import Ecto.{Changeset, Query}
      alias Pgvector.Ecto.Vector

      def table_name do
        unquote(table_name)
      end

      schema unquote(table_name) do
        field :embedding, Vector
        belongs_to :doc_fragment, Packages.DocFragment

        timestamps(type: :utc_datetime)
      end

      def changeset(embedding, attrs) do
        embedding
        |> cast(attrs, [:embedding])
        |> cast_assoc(:doc_fragment, required: true)
        |> validate_required([:embedding])
      end

      def embedding_size, do: unquote(embedding_size)
      def batch_size, do: unquote(batch_size)

      def child_spec(opts) do
        opts
        |> Keyword.merge(serving: load_model())
        |> Nx.Serving.child_spec()
      end

      def embed() do
        fragments =
          from f in Packages.DocFragment,
            left_join: e in __MODULE__,
            on: e.doc_fragment_id == f.id,
            where: is_nil(e)

        fragments = Repo.all(fragments)

        fragment_texts = fragments |> unquote(text_batching)

        embeddings =
          fragment_texts
          |> Stream.with_index(1)
          |> Stream.flat_map(fn {text, index} ->
            embeddings = Nx.Serving.batched_run(__MODULE__, text)

            case embeddings do
              %{embedding: embedding} ->
                embedding

              _ when is_list(embeddings) ->
                Stream.map(embeddings, & &1.embedding)
            end
          end)

        Repo.transaction(fn ->
          [fragments, embeddings]
          |> Stream.zip()
          |> Enum.map(fn {fragment, embedding} ->
            Repo.insert!(%__MODULE__{
              embedding: embedding,
              doc_fragment: fragment
            })
          end)
        end)
      end

      defp load_model do
        {:ok, model_info} = Bumblebee.load_model(unquote(model_repo), unquote(load_model_opts))

        {:ok, tokenizer} =
          Bumblebee.load_tokenizer(unquote(model_repo), unquote(load_tokenizer_opts))

        Bumblebee.Text.text_embedding(model_info, tokenizer, unquote(serving_opts))
      end
    end
  end
end
