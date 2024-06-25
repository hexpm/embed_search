defmodule Search.PackagesTest do
  use Search.DataCase

  alias Search.Packages

  import Search.PackagesFixtures

  describe "doc_fragments" do
    alias Search.Packages.DocFragment

    test "create_doc_fragment/2 with valid data creates an item" do
      [item] = doc_items_fixture(1)

      valid_attrs = %{
        text: "Some text",
        order: 0
      }

      assert {:ok, %DocFragment{} = fragment} = Packages.create_doc_fragment(item, valid_attrs)
      assert fragment.text == valid_attrs.text
      fragment = Repo.preload(fragment, :doc_item)
      assert fragment.doc_item.id == item.id
    end

    test "create_doc_fragment/2 with invalid data returns error changeset" do
      [item] = doc_items_fixture(1)

      assert {:error, %Ecto.Changeset{}} =
               Packages.create_doc_fragment(item, %{text: nil})
    end
  end

  describe "doc_items" do
    alias Search.Packages.DocItem

    test "create_doc_item/2 with valid data creates an item" do
      package = package_fixture()

      valid_attrs = %{
        title: "Some title",
        type: "module",
        ref: "Some ref"
      }

      assert {:ok, %DocItem{} = item} = Packages.create_doc_item(package, valid_attrs)
      assert item.title == valid_attrs.title
      assert item.type == valid_attrs.type
      assert item.ref == valid_attrs.ref
      item = Repo.preload(item, :package)
      assert item.package.id == package.id
    end

    test "create_doc_item/2 with invalid data returns error changeset" do
      package = package_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Packages.create_doc_item(package, %{title: nil, type: nil, doc: nil, ref: nil})
    end
  end

  describe "packages" do
    alias Search.Packages.Package

    @invalid_attrs %{name: nil, version: nil}

    test "list_packages/0 returns all packages" do
      package = package_fixture()
      assert Packages.list_packages() == [package]
    end

    test "get_package!/1 returns the package with given id" do
      package = package_fixture()
      assert Packages.get_package!(package.id) == package
    end

    test "create_package/1 with valid data creates a package" do
      valid_attrs = %{name: "some name", version: "some version"}

      assert {:ok, %Package{} = package} = Packages.create_package(valid_attrs)
      assert package.name == "some name"
      assert package.version == "some version"
    end

    test "create_package/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Packages.create_package(@invalid_attrs)
    end

    test "update_package/2 with valid data updates the package" do
      package = package_fixture()
      update_attrs = %{name: "some updated name", version: "some updated version"}

      assert {:ok, %Package{} = package} = Packages.update_package(package, update_attrs)
      assert package.name == "some updated name"
      assert package.version == "some updated version"
    end

    test "update_package/2 with invalid data returns error changeset" do
      package = package_fixture()
      assert {:error, %Ecto.Changeset{}} = Packages.update_package(package, @invalid_attrs)
      assert package == Packages.get_package!(package.id)
    end

    test "delete_package/1 deletes the package" do
      package = package_fixture()
      assert {:ok, %Package{}} = Packages.delete_package(package)
      assert_raise Ecto.NoResultsError, fn -> Packages.get_package!(package.id) end
    end

    test "change_package/1 returns a package changeset" do
      package = package_fixture()
      assert %Ecto.Changeset{} = Packages.change_package(package)
    end
  end
end
