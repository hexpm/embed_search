defmodule Search.MigrationHelper do
  defmacro change(module) do
    quote do
      create table(String.to_atom(unquote(module).table_name())) do
        add :embedding, :vector, size: unquote(module).embedding_size(), null: false
        add :doc_fragment_id, references("doc_fragments", on_delete: :delete_all), null: false

        timestamps(type: :utc_datetime)
      end
    end
  end
end
