defmodule Search.Embeddings.Embedding do
  alias Search.Packages
  alias Pgvector.Ecto.Vector

  defmacro __using__(attrs \\ []) do
    %{model: model_repo, embedding_size: embedding_size, compile_opts: compile_opts} =
      attrs
      |> Keyword.validate!([:model, :embedding_size, compile_opts: []])
      |> Keyword.take([:model, :embedding_size, :compile_opts])
      |> Map.new()

    batch_size = Keyword.get(compile_opts, :batch_size)

    quote do
      alias Search.Packages
      use Ecto.Schema
      import Ecto.Changeset

      def table_name do
        "#{Macro.underscore(__MODULE__)}_embeddings"
      end

      schema table_name() do
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
        {:ok, model_info} = Bumblebee.load_model(unquote(model_repo))
        {:ok, tokenizer} = Bumblebee.load_tokenizer(unquote(model_repo))

        Bumblebee.Text.text_embedding(model_info, tokenizer,
          compile: unquote(compile_opts),
          defn_options: [compiler: EXLA]
        )
      end
    end
  end
end
