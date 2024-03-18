defmodule Search.Packages.Package do
  alias Search.Packages
  use Ecto.Schema
  import Ecto.Changeset

  schema "packages" do
    field :name, :string
    field :version, :string
    has_many :doc_items, Packages.DocItem

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(package, attrs) do
    package
    |> cast(attrs, [:name, :version])
    |> validate_required([:name, :version])
  end
end
