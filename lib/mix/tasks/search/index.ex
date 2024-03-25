defmodule Mix.Tasks.Search.Index do
  @moduledoc """
  Usage: mix #{Mix.Task.task_name(__MODULE__)} <PACKAGE> [<VERSION>]

  Fetches the documentation for the given package from Hex and indexes it using the embedding model.

  If the version is ommitted, it will choose the newest release.
  """
  @shortdoc "Indexes a package's documentation"

  use Mix.Task

  @requirements ["app.start"]

  @impl Mix.Task
  def run(args) do
    [package | args_tail] = args
    {:ok, releases} = Search.HexClient.get_releases(package)

    release =
      case args_tail do
        [version] ->
          version = Version.parse!(version)
          Enum.find(releases, &(&1.version == version))

        [] ->
          Enum.max_by(releases, & &1.version, Version, fn -> nil end)
      end

    if release do
      {:ok, tarball} = Search.HexClient.get_docs_tarball(release)
      {:ok, docs} = Search.ExDocParser.extract_search_data(tarball)
      docs = Enum.map(docs, & &1["doc"])
      docs_len = length(docs)

      ProgressBar.render(0, docs_len)

      # docs
      # |> Stream.with_index(1)
      # |> Enum.each(fn {doc, i} ->
      #   %{embedding: embedding} = Nx.Serving.batched_run(Search.Embedding, doc)

      #   ProgressBar.render(i, docs_len)

      #   fragment = %Search.Fragment{doc_text: doc, embedding: embedding}

      #   Search.Repo.insert!(fragment)
      # end)
    else
      Mix.shell().error("Release not found.")
    end
  end
end
