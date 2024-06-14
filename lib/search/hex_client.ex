defmodule Search.HexClient do
  @repo_url "https://repo.hex.pm"

  alias Search.HexClient

  def get_releases(package_name) when is_binary(package_name) do
    case get("packages/#{package_name}") do
      {:ok, %{status: 200, body: releases}} ->
        res =
          for %{version: version} <- releases do
            %HexClient.Release{
              package_name: package_name,
              version: Version.parse!(version)
            }
          end

        {:ok, res}

      {:ok, %{status: status}} ->
        {:error, "HTTP #{status}"}

      {:error, ex} when is_exception(ex) ->
        {:error, Exception.message(ex)}

      err ->
        err
    end
  end

  def get_docs_tarball(
        %HexClient.Release{package_name: package_name, version: version} =
          _release
      ) do
    case get("docs/#{package_name}-#{version}.tar.gz") do
      {:ok, %{status: 200, body: body}} ->
        {:ok, body}

      {:ok, %{status: status}} ->
        {:error, "HTTP #{status}"}

      {:error, ex} when is_exception(ex) ->
        {:error, Exception.message(ex)}

      err ->
        err
    end
  end

  defp get(resource, opts \\ []) do
    opts
    |> Keyword.merge(Application.get_env(:search, :hex_client_req_options, []))
    |> Keyword.merge(url: "#{@repo_url}/#{resource}")
    |> Req.new()
    |> ReqHex.attach()
    |> Req.request()
  end
end
