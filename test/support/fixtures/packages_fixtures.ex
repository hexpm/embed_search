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
        version: "some version"
      })
      |> Search.Packages.create_package()

    package
  end

  def doc_fragments_fixture(num_fragments \\ 10) do
    package =
      Search.Repo.insert!(%Search.Packages.Package{
        name: "Test package",
        version: "1.0.1"
      })

    fragments =
      for i <- 1..num_fragments do
        item =
          Search.Repo.insert!(%Search.Packages.DocItem{
            title: "Module doc title",
            ref: "Test ref",
            doc: "Text #{i}",
            type: "module",
            package: package
          })

        fragment =
          Search.Repo.insert!(%Search.Packages.DocFragment{
            text: "Preprocessed text #{i}",
            doc_item: item
          })

        fragment
      end

    fragments
  end
end
