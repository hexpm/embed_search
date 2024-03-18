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
end
