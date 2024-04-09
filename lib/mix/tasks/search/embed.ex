defmodule Mix.Tasks.Search.Embed do
  @moduledoc """
  Usage: mix #{Mix.Task.task_name(__MODULE__)} <MODULE>

  Embeds the unembedded docs using the given model given as `Search.Embeddings.<MODULE>`
  """
  @shortdoc "Embeds the unembedded doc fragments"

  use Mix.Task

  @requirements ["app.start"]

  defp callback({total, done}) do
    ProgressBar.render(done, total)
  end

  @impl Mix.Task
  def run([module_str]) do
    module =
      Enum.find(Search.Application.embedding_models(), fn mod ->
        "Elixir.Search.Embeddings.#{module_str}" == "#{mod}"
      end)

    if module do
      {:ok, _} = module.embed(&callback/1)
      Mix.shell().info("Done.")
    else
      Mix.shell().error("Could not find embedding module #{module_str}.")
    end
  end
end
