defmodule Search.Packages.DocFragment do
  alias Search.Packages
  use Ecto.Schema
  import Ecto.Changeset

  schema "doc_fragments" do
    field :text, :string
    field :order, :integer

    belongs_to :doc_item, Packages.DocItem

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(doc_fragment, attrs) do
    doc_fragment
    |> cast(attrs, [:text, :order])
    |> cast_assoc(:doc_item)
    |> validate_required([:text, :order])
  end
end
