defmodule Search.Packages.DocItem do
  alias Search.Packages
  use Ecto.Schema
  import Ecto.Changeset

  schema "doc_items" do
    field :type, :string
    field :title, :string
    field :ref, :string
    field :doc, :string
    belongs_to :package, Packages.Package
    has_many :doc_fragments, Packages.DocFragment

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(doc_item, attrs) do
    doc_item
    |> cast(attrs, [:ref, :type, :title, :doc, :package])
    |> validate_required([:ref, :type, :title, :doc, :package])
  end
end