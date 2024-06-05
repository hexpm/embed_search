defmodule Search.Packages do
  @moduledoc """
  The Packages context.
  """

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
        latest = find_latest_release(releases)
        add_package(latest)

      err ->
        err
    end
  end

  def add_package(%HexClient.Release{package_name: package_name, version: version} = release) do
    version = Version.to_string(version)

    with {:ok, docs} <- HexClient.get_docs_tarball(release),
         {:ok, search_data} <- ExDocParser.extract_search_data(docs) do
      Repo.transaction(fn ->
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
          |> Repo.insert_or_update()

        with {:ok, package} <- package,
             :ok <- create_items_from_package(package, search_data) do
          package
        else
          {:error, err} ->
            Repo.rollback(err)
        end
      end)
    else
      err -> err
    end
  end

  defp find_latest_release([]), do: nil

  defp find_latest_release([%HexClient.Release{} = releases_head | releases_tail]) do
    if releases_head.version.pre do
      find_latest_release(releases_tail, nil, releases_head, true)
    else
      find_latest_release(releases_tail, releases_head, nil, false)
    end
  end

  defp find_latest_release([], latest_release, latest_pre, all_pre?) do
    if all_pre? do
      latest_pre
    else
      latest_release
    end
  end

  defp find_latest_release(
         [%HexClient.Release{version: head_version} = releases_head | releases_tail],
         latest_release,
         latest_pre,
         all_pre?
       ) do
    cond do
      head_version.pre and
          (is_nil(latest_pre) or Version.compare(head_version, latest_pre.version) == :gt) ->
        # there is a new latest prerelease
        find_latest_release(releases_tail, latest_release, releases_head, all_pre?)

      is_nil(latest_release) or Version.compare(head_version, latest_release.version) == :gt ->
        # there is a new latest release, we can be sure there are no longer only prerelease entries
        find_latest_release(releases_tail, releases_head, latest_pre, false)

      head_version.pre ->
        # not a new latest prerelease, but a prerelease nonetheless
        find_latest_release(releases_tail, latest_release, latest_pre, all_pre?)

      true ->
        # not a new latest release, but we are sure there is at least one non-prerelease entry
        find_latest_release(releases_tail, latest_release, latest_pre, false)
    end
  end

  defp create_items_from_package(%Package{} = package, search_data) do
    for %{"doc" => doc, "title" => title, "ref" => ref, "type" => type} <- search_data do
      with {:ok, item} <-
             create_doc_item(package, %{doc: doc, title: title, ref: ref, type: type}),
           {:ok, _fragment} <-
             create_doc_fragment(item, %{
               text: "# #{title}\n\n#{doc}"
             }) do
      else
        {:error, err} ->
          Repo.rollback(err)
      end
    end

    :ok
  end

  @doc """
  Creates a doc fragment.
  """
  def create_doc_fragment(%DocItem{id: item_id} = _doc_item, attrs) do
    %DocFragment{doc_item_id: item_id}
    |> DocFragment.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Creates a doc item.
  """
  def create_doc_item(%Package{id: package_id} = _package, attrs) do
    %DocItem{package_id: package_id}
    |> DocItem.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Returns the list of packages.

  ## Examples

      iex> list_packages()
      [%Package{}, ...]

  """
  def list_packages do
    Repo.all(Package)
  end

  @doc """
  Gets a single package.

  Raises `Ecto.NoResultsError` if the Package does not exist.

  ## Examples

      iex> get_package!(123)
      %Package{}

      iex> get_package!(456)
      ** (Ecto.NoResultsError)

  """
  def get_package!(id), do: Repo.get!(Package, id)

  @doc """
  Creates a package.

  ## Examples

      iex> create_package(%{field: value})
      {:ok, %Package{}}

      iex> create_package(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_package(attrs \\ %{}) do
    %Package{}
    |> Package.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a package.

  ## Examples

      iex> update_package(package, %{field: new_value})
      {:ok, %Package{}}

      iex> update_package(package, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_package(%Package{} = package, attrs) do
    package
    |> Package.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a package.

  ## Examples

      iex> delete_package(package)
      {:ok, %Package{}}

      iex> delete_package(package)
      {:error, %Ecto.Changeset{}}

  """
  def delete_package(%Package{} = package) do
    Repo.delete(package)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking package changes.

  ## Examples

      iex> change_package(package)
      %Ecto.Changeset{data: %Package{}}

  """
  def change_package(%Package{} = package, attrs \\ %{}) do
    Package.changeset(package, attrs)
  end
end
