defmodule SearchWeb.PageController do
  use SearchWeb, :controller

  @empty_form Phoenix.Component.to_form(%{
                "search_text" => nil,
                "k" => nil,
                "embedding_model" => nil
              })

  @embedding_model_opts Search.Application.embedding_models()
                        |> Enum.map(&(&1 |> Module.split() |> Enum.reverse() |> Enum.at(0)))

  def home(conn, _params) do
    # The home page is often custom made,
    # so skip the default app layout.
    render(conn, :home, form: @empty_form, embedding_models: @embedding_model_opts)
  end

  def search(
        conn,
        %{"k" => k, "search_text" => search_text, "embedding_model" => embedding_model} = params
      ) do
    model =
      Enum.find(Search.Application.embedding_models(), fn mod ->
        "Elixir.Search.Embeddings.#{embedding_model}" == "#{mod}"
      end)

    k = String.to_integer(k)
    search_text = String.trim(search_text)

    errors =
      if search_text == "" do
        [search_text: {"Can't be blank", []}]
      else
        []
      end

    if errors == [] do
      %{embedding: query_tensor} = Nx.Serving.batched_run(model, search_text)

      items =
        Search.Embeddings.knn_query(model, query_tensor, k: k)
        |> Stream.map(& &1.doc_fragment.doc_item)
        |> Enum.uniq_by(& &1.id)

      render(conn, :search, items: items)
    else
      render(conn, :home, form: Phoenix.Component.to_form(params, errors: errors))
    end
  end
end
