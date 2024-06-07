defmodule Search.Packages do
  import Ecto.Query, warn: false
  alias Search.Repo

  alias Search.Packages.{Package, DocItem, DocFragment}
  alias Search.{HexClient, ExDocParser}

  @doc """
  Adds the package to be indexed by the application.

  If given a package name, adds the latest version of the package to the app. If given a `%HexClient.Release{}` adds
  the specified release. Does not embed it yet.
  """
  def add_package(package_name) when is_binary(package_name) do
    case HexClient.get_releases(package_name) do
      {:ok, releases} ->
        latest = HexClient.Release.latest(releases)
        add_package(latest)

      err ->
        err
    end
  end

  def add_package(%HexClient.Release{package_name: package_name, version: version} = release) do
    version = Version.to_string(version)

    with {:ok, docs} <- HexClient.get_docs_tarball(release),
         {:ok, search_data} <- ExDocParser.extract_search_data(docs) do
      Repo.transaction_with(fn ->
        package =
          case Repo.get_by(Package, name: package_name) do
            nil ->
              %Package{name: package_name, version: version}

            existing ->
              existing
          end
          |> Repo.preload(:doc_items)
          |> Package.changeset(%{
            version: version
          })
          |> Ecto.Changeset.put_assoc(:doc_items, [])

        with {:ok, package} <- Repo.insert_or_update(package),
             :ok <- create_items_from_package(package, search_data) do
          {:ok, package}
        else
          {:error, _} = err ->
            err
        end
      end)
    else
      err -> err
    end
  end

  defp create_items_from_package(%Package{} = _package, []), do: :ok

  defp create_items_from_package(%Package{} = package, [search_data_head | search_data_tail]) do
    %{"doc" => doc, "title" => title, "ref" => ref, "type" => type} = search_data_head

    with {:ok, item} <-
           create_doc_item(package, %{doc: doc, title: title, ref: ref, type: type}),
         {:ok, _fragment} <-
           create_doc_fragment(item, %{
             text: "# #{title}\n\n#{doc}"
           }) do
      create_items_from_package(package, search_data_tail)
    else
      {:error, _} = err ->
        err
    end
  end

  def create_doc_fragment(%DocItem{id: item_id} = _doc_item, attrs) do
    %DocFragment{doc_item_id: item_id}
    |> DocFragment.changeset(attrs)
    |> Repo.insert()
  end

  def create_doc_item(%Package{id: package_id} = _package, attrs) do
    %DocItem{package_id: package_id}
    |> DocItem.changeset(attrs)
    |> Repo.insert()
  end

  def list_packages do
    Repo.all(Package)
  end

  def get_package!(id), do: Repo.get!(Package, id)

  def create_package(attrs \\ %{}) do
    %Package{}
    |> Package.changeset(attrs)
    |> Repo.insert()
  end

  def update_package(%Package{} = package, attrs) do
    package
    |> Package.changeset(attrs)
    |> Repo.update()
  end

  def delete_package(%Package{} = package) do
    Repo.delete(package)
  end

  def change_package(%Package{} = package, attrs \\ %{}) do
    Package.changeset(package, attrs)
  end
end
