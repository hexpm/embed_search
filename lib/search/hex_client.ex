defmodule Search.HexClient do
  @api_url "https://hex.pm/api"
  @repo_url "https://repo.hex.pm"

  alias Search.HexClient

  def get_releases(package_name) when is_binary(package_name) do
    case get("#{@api_url}/packages/#{package_name}") do
      {:ok, %{status: 200, body: %{"releases" => releases}}} ->
        map_json_to_releases(package_name, releases)

      {:ok, %{status: status}} ->
        {:error, "HTTP #{status}"}

      err ->
        err
    end
  end

  defp map_json_to_releases(package_name, releases_json) do
    map_json_to_releases(package_name, releases_json, [])
  end

  defp map_json_to_releases(_package_name, [] = _releases_json, acc) do
    {:ok, Enum.reverse(acc)}
  end

  defp map_json_to_releases(
         package_name,
         [%{"has_docs" => has_docs, "version" => version} | tail] = _releases_json,
         acc
       ) do
    release = %HexClient.Release{
      package_name: package_name,
      version: Version.parse!(version),
      has_docs: has_docs
    }

    acc = [release | acc]
    map_json_to_releases(package_name, tail, acc)
  end

  def get_docs_tarball(
        %HexClient.Release{has_docs: has_docs, package_name: package_name, version: version} =
          _release
      ) do
    if has_docs do
      case get("#{@repo_url}/docs/#{package_name}-#{version}.tar.gz") do
        {:ok, %{status: 200, body: body}} -> {:ok, body}
        {:ok, %{status: status}} -> {:error, "HTTP #{status}"}
        err -> err
      end
    else
      {:error, "Package release has no documentation."}
    end
  end

  defp get(url) do
    Req.get(url, Application.get_env(:search, :hex_client_req_options, []))
  end
end
