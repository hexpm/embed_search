defmodule Mix.Tasks.Search.Add do
  alias Search.Packages
  alias Search.HexClient

  @moduledoc """
  Usage: mix #{Mix.Task.task_name(__MODULE__)} <PACKAGE> [--version <VERSION>] [--max-size <MAX_SIZE>]

  Fetches the documentation for the given package from Hex. Does not embed it yet.

  If the version is ommitted, it will choose the newest release.
  """
  @shortdoc "Adds a package's documentation to the index"

  use Mix.Task

  @requirements ["app.start"]

  @impl Mix.Task
  def run(args) do
    case OptionParser.parse(args, strict: [version: :string, max_size: :integer]) do
      {opts, [package_name], []} ->
        version = Keyword.get(opts, :version)
        fragmentation_opts = Keyword.take(opts, [:max_size])

        with {:ok, package_or_release} <- package_or_release(package_name, version),
             {:ok, package} <-
               Packages.add_package(package_or_release, fragmentation_opts: fragmentation_opts) do
          Mix.shell().info("Package #{package.name}@#{package.version} added.")
        else
          {:error, err} ->
            Mix.shell().error("Error: #{err}")
        end

      {_opts, [], []} ->
        Mix.shell().error("Expected a package name as one of the arguments.")

      {_opts, _more_than_one, []} ->
        Mix.shell().error("Too many arguments.")

      {_opts, _, invalid} ->
        invalid =
          invalid
          |> Enum.map(&elem(&1, 0))
          |> Enum.join(", ")

        Mix.shell().error("Incorrect or unknown options: #{invalid}")
    end
  end

  defp package_or_release(package_name, nil), do: {:ok, package_name}

  defp package_or_release(package_name, version) do
    case Version.parse(version) do
      {:ok, version} -> {:ok, %HexClient.Release{package_name: package_name, version: version}}
      :error -> {:error, "Could not parse the requested version."}
    end
  end
end
