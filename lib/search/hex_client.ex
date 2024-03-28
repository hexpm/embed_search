defmodule Search.HexClient do
  @repo_url "https://repo.hex.pm"

  alias Search.HexClient

  def get_releases(package_name) when is_binary(package_name) do
    case get("packages/#{package_name}", plugins: [ReqHex]) do
      {:ok, %{status: 200, body: releases}} ->
        res =
          for %{version: version} <- releases do
            %HexClient.Release{
              package_name: package_name,
              version: Version.parse!(version)
            }
          end

        {:ok, res}

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

      err ->
        err
    end
  end

  defp get(resource, opts \\ []) do
    {_req, res} =
      opts
      |> Keyword.merge(Application.get_env(:search, :hex_client_req_options, []))
      |> Keyword.merge(url: "#{@repo_url}/#{resource}")
      |> Req.new()
      |> Req.Request.prepend_response_steps(
        handle_errors: fn {req, res} ->
          # Looks like ReqHex fails in zlib on non-200 codes, so these are handled here
          case res do
            %{status: 200} -> {req, res}
            %{status: status} -> {Req.Request.halt(req), RuntimeError.exception("HTTP #{status}")}
          end
        end
      )
      |> Req.Request.run_request()

    case res do
      %RuntimeError{message: message} -> {:error, message}
      other -> {:ok, other}
    end
  end
end
