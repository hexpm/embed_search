defmodule Search.Packages.DocFragment do
  alias Search.Packages
  use Ecto.Schema
  import Ecto.Changeset

  schema "doc_fragments" do
    field :text, :string
    belongs_to :doc_item, Packages.DocItem

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(doc_fragment, attrs) do
    doc_fragment
    |> cast(attrs, [:text])
    |> validate_required([:text])
  end
end
