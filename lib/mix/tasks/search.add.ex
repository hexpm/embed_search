defmodule Mix.Tasks.Search.Add do
  alias Search.Packages
  alias Search.HexClient

  @moduledoc """
  Usage: mix #{Mix.Task.task_name(__MODULE__)} <PACKAGE> [<VERSION>]

  Fetches the documentation for the given package from Hex. Does not embed it yet.

  If the version is ommitted, it will choose the newest release.
  """
  @shortdoc "Adds a package's documentation to the index"

  use Mix.Task

  @requirements ["app.start"]

  @impl Mix.Task
  def run(args) do
    [package | args_tail] = args

    package_or_release =
      case args_tail do
        [version] ->
          version = Version.parse!(version)
          %HexClient.Release{package_name: package, version: version}

        [] ->
          package
      end

    case Packages.add_package(package_or_release) do
      {:ok, package} -> Mix.shell().info("Package #{package.name}@#{package.version} added.")
      {:error, err} -> Mix.shell().error("Error: #{err}")
    end
  end
end
