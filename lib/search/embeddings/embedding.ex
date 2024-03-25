defmodule Search.Embeddings.Embedding do
  alias Search.Packages
  alias Pgvector.Ecto.Vector

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

    quote do
      alias Search.Packages
      use Ecto.Schema
      import Ecto.Changeset

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
        |> cast(attrs, [:embedding, :doc_fragment])
        |> validate_required([:embedding, :doc_fragment])
      end

      def embedding_size, do: unquote(embedding_size)
      def batch_size, do: unquote(batch_size)

      def child_spec(opts) do
        opts
        |> Keyword.merge(serving: load_model())
        |> Nx.Serving.child_spec()
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
