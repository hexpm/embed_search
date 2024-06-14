defmodule Mix.Tasks.Search.Embed do
  @moduledoc """
  Usage: mix #{Mix.Task.task_name(__MODULE__)} <MODEL_NAME>

  Embeds the unembedded docs using the model registered in the config
  """
  @shortdoc "Embeds the unembedded doc fragments"

  use Mix.Task

  @requirements ["app.start"]

  defp callback({total, done}) do
    ProgressBar.render(done, total)
  end

  @impl Mix.Task
  def run([model_name]) do
    embedding_models =
      Search.Application.embedding_models()
      |> Keyword.keys()
      |> Enum.map(&Atom.to_string/1)

    if Enum.member?(embedding_models, model_name) do
      Search.Embeddings.embed(String.to_existing_atom(model_name), &callback/1)
      Mix.shell().info("Done.")
    else
      Mix.shell().error("Expected model name to be one of: #{Enum.join(embedding_models, ", ")}.")
    end
  end
end
