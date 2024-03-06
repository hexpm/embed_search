defmodule SearchWeb.PageController do
  use SearchWeb, :controller

  def home(conn, _params) do
    # The home page is often custom made,
    # so skip the default app layout.
    render(conn, :home, form: Phoenix.Component.to_form(%{"search_text" => nil, "k" => nil}))
  end

  def search(conn, %{"k" => k, "search_text" => search_text} = params) do
    k = String.to_integer(k)
    search_text = String.trim(search_text)

    errors =
      if search_text == "" do
        [search_text: {"Can't be blank", []}]
      else
        []
      end

    if errors == [] do
      %{embedding: query_tensor} = Nx.Serving.batched_run(Search.Embedding, search_text)
      fragments = Search.Fragment.knn_lookup(query_tensor, k: k)

      render(conn, :search, fragments: fragments)
    else
      render(conn, :home, form: Phoenix.Component.to_form(params, errors: errors))
    end
  end
end
