defmodule Search.HexClient do
  @hexpm_url "https://hex.pm/api"
  @hex_repo_url "https://repo.hex.pm"

  @headers %{"content-type" => "application/json"}

  alias Search.HexClient

  def get_releases(package_name) when is_binary(package_name) do
    case Req.get("#{@hexpm_url}/packages/#{package_name}", req_options()) do
      {:ok, %{body: %{"releases" => releases}}} ->
        map_json_to_releases(package_name, releases, [])

      {:ok, _} ->
        {:error, "Response does not have a \"releases\" key."}

      err ->
        err
    end
  end

  defp map_json_to_releases(package_name, releases_json, into) do
    {acc, collect_fn} = Collectable.into(into)
    map_json_to_releases(package_name, releases_json, acc, collect_fn)
  end

  defp map_json_to_releases(_package_name, [] = _releases_json, acc, collect_fn) do
    {:ok, collect_fn.(acc, :done)}
  end

  defp map_json_to_releases(package_name, [head | tail] = _releases_json, acc, collect_fn) do
    with %{"has_docs" => has_docs, "version" => version} <- head do
      case Version.parse(version) do
        {:ok, version} ->
          release = %HexClient.Release{
            package_name: package_name,
            version: version,
            has_docs: has_docs
          }

          acc = collect_fn.(acc, {:cont, release})
          map_json_to_releases(package_name, tail, acc, collect_fn)

        err ->
          collect_fn.(acc, :halt)
          err
      end
    else
      _ ->
        collect_fn.(acc, :halt)
        {:error, "Release does not have required keys \"has_docs\" and \"version\"."}
    end
  end

  def get_docs_tarball(
        %HexClient.Release{has_docs: has_docs, package_name: package_name, version: version} =
          _release
      ) do
    if has_docs do
      case Req.get(
             "#{@hex_repo_url}/docs/#{package_name}-#{Version.to_string(version)}.tar.gz",
             req_options()
           ) do
        {:ok, res} -> {:ok, res.body}
        err -> err
      end
    else
      {:error, "Package release has no documentation."}
    end
  end

  defp req_options do
    Keyword.merge([headers: @headers], Application.get_env(:search, :hex_client_req_options, []))
  end
end
