defmodule Search.MigrationHelper do
  defmacro change(module) do
    table_name = String.to_atom(module.table_name())

    quote do
      create table(unquote(table_name)) do
        add :embedding, :vector, size: unquote(module).embedding_size(), null: false
        add :doc_fragment_id, references("doc_fragments", on_delete: :delete_all), null: false

        timestamps(type: :utc_datetime)
      end
    end
  end
end
