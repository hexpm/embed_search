defmodule Search.Packages.DocItem do
  alias Search.Packages
  use Ecto.Schema
  import Ecto.Changeset

  schema "doc_items" do
    field :type, :string
    field :title, :string
    field :ref, :string
    belongs_to :package, Packages.Package

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(doc_item, attrs) do
    doc_item
    |> cast(attrs, [:ref, :type, :title])
    |> validate_required([:ref, :type, :title])
  end
end
