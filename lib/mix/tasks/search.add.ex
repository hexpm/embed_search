defmodule Mix.Tasks.Search.Add do
  alias Search.Packages
  alias Search.HexClient

  @moduledoc """
  Usage: mix #{Mix.Task.task_name(__MODULE__)} <PACKAGE> [version:<VERSION>] [max_size:<MAX_SIZE>]

  Fetches the documentation for the given package from Hex. Does not embed it yet.

  If the version is ommitted, it will choose the newest release.
  """
  @shortdoc "Adds a package's documentation to the index"

  use Mix.Task

  @requirements ["app.start"]

  @impl Mix.Task
  def run(args) do
    [package_name | args_tail] = args

    with {:ok, args} <- parse_args(args_tail, []),
         version = Keyword.get(args, :version),
         fragmentation_opts = Keyword.take(args, [:max_size]),
         package_or_release = package_or_release(package_name, version),
         {:ok, package} <-
           Packages.add_package(package_or_release, fragmentation_opts: fragmentation_opts) do
      Mix.shell().info("Package #{package.name}@#{package.version} added.")
    else
      {:error, err} -> Mix.shell().error("Error: #{err}")
    end
  end

  defp package_or_release(package_name, nil), do: package_name

  defp package_or_release(package_name, version) do
    %HexClient.Release{package_name: package_name, version: version}
  end

  defp parse_args([], acc), do: {:ok, acc}

  defp parse_args([arg | args_tail], acc) do
    case arg do
      "version:" <> version ->
        case Version.parse(version) do
          {:ok, version} -> parse_args(args_tail, Keyword.put(acc, :version, version))
          :error -> {:error, ~c(Could not parse the "version" arg value)}
        end

      "max_size:" <> max_size ->
        case Integer.parse(max_size) do
          {max_size, ""} -> parse_args(args_tail, Keyword.put(acc, :max_size, max_size))
          _ -> {:error, ~c(Could not parse the "max_size" arg value)}
        end

      _ ->
        {:error, ~c(Unknown argument: "#{arg}")}
    end
  end
end
