defmodule Mix.Tasks.Search.Embed do
  @moduledoc """
  Usage: mix #{Mix.Task.task_name(__MODULE__)} <MODULE>

  Embeds the unembedded docs using the model registered in the config
  """
  @shortdoc "Embeds the unembedded doc fragments"

  use Mix.Task

  @requirements ["app.start"]

  defp callback({total, done}) do
    ProgressBar.render(done, total)
  end

  @impl Mix.Task
  def run([module_key]) do
    Search.Embeddings.embed(String.to_existing_atom(module_key), &callback/1)
    Mix.shell().info("Done.")
  end
end
