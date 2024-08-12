defmodule Search.PackagesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Search.Packages` context.
  """

  @doc """
  Generate a package.
  """
  def package_fixture(attrs \\ %{}) do
    {:ok, package} =
      attrs
      |> Enum.into(%{
        name: "some name",
        version: "1.2.3"
      })
      |> Search.Packages.create_package()

    package
  end

  def doc_items_fixture(num_items) do
    package = package_fixture()

    for i <- 1..num_items do
      Search.Repo.insert!(%Search.Packages.DocItem{
        title: "Module doc title #{i}",
        ref: "Test ref",
        type: "module",
        package: package
      })
    end
  end

  def doc_fragments_fixture(num_fragments) do
    items =
      doc_items_fixture(num_fragments)

    for item <- items do
      Search.Repo.insert!(%Search.Packages.DocFragment{
        text: "Preprocessed text for #{item.title}",
        order: 0,
        doc_item: item
      })
    end
  end
end
