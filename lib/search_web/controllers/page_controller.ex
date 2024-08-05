defmodule SearchWeb.PageController do
  use SearchWeb, :controller

  @empty_form Phoenix.Component.to_form(%{
                "search_text" => nil,
                "k" => nil,
                "embedding_model" => nil
              })

  @embedding_model_opts Search.Application.embedding_models()
                        |> Keyword.keys()

  def home(conn, _params) do
    # The home page is often custom made,
    # so skip the default app layout.
    render(conn, :home, form: @empty_form, embedding_models: @embedding_model_opts)
  end

  def search(
        conn,
        %{"k" => k, "search_text" => search_text, "embedding_model" => embedding_model} = params
      ) do
    embedding_model = String.to_existing_atom(embedding_model)
    k = String.to_integer(k)
    search_text = String.trim(search_text)

    errors =
      if search_text == "" do
        [search_text: {"Can't be blank", []}]
      else
        []
      end

    if errors == [] do
      query_tensor = Search.Embeddings.embed_one(embedding_model, search_text)

      items =
        Search.Embeddings.knn_query(embedding_model, query_tensor, k: k)
        |> Stream.map(& &1.doc_fragment.doc_item)
        |> Enum.uniq_by(& &1.id)
        |> Search.Repo.preload(:doc_fragments)
        |> Stream.map(fn item ->
          doc_content =
            item.doc_fragments
            |> Enum.sort_by(& &1.order)
            |> Enum.map(& &1.text)
            |> Search.FragmentationScheme.recombine()

          {item, doc_content}
        end)

      render(conn, :search, items: items)
    else
      render(conn, :home, form: Phoenix.Component.to_form(params, errors: errors))
    end
  end
end
