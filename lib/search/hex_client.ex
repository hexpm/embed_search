defmodule Search.HexClient do
  @hexpm_url "https://hex.pm/api"
  @hex_repo_url "https://repo.hex.pm"

  @headers %{"content-type" => "application/json"}

  alias Search.HexClient

  def get_releases!(package_name) when is_binary(package_name) do
    res =
      Req.get!("#{@hexpm_url}/packages/#{package_name}", req_options())

    res.body["releases"]
    |> Stream.map(fn %{"has_docs" => has_docs, "version" => version} ->
      %HexClient.Release{
        package_name: package_name,
        has_docs: has_docs,
        version: Version.parse!(version)
      }
    end)
    |> Enum.sort_by(& &1.version, {:desc, Version})
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
        {:ok, res} -> res.body
        err -> err
      end
    else
      {:error, "Package release has no documentation"}
    end
  end

  defp req_options do
    Keyword.merge([headers: @headers], Application.get_env(:search, :hex_client_req_options, []))
  end
end
