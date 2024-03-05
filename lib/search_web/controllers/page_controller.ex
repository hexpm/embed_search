defmodule SearchWeb.PageController do
  use SearchWeb, :controller

  def home(conn, _params) do
    # The home page is often custom made,
    # so skip the default app layout.
    render(conn, :home, form: Phoenix.Component.to_form(%{"search_text" => nil, "k" => nil}))
  end

  def search(conn, %{"k" => k, "search_text" => search_text} = params) do
    k = String.trim(k)
    search_text = String.trim(search_text)

    errors =
      if search_text == "" do
        [search_text: {"Can't be blank", []}]
      else
        []
      end

    {k, errors} =
      case Integer.parse(k) do
        _ when k == "" ->
          {nil, Keyword.merge(errors, k: {"Can't be blank", []})}

        :error ->
          {nil, Keyword.merge(errors, k: {"Must be an integer", []})}

        {k, _rest} when k < 1 ->
          {nil, Keyword.merge(errors, k: {"Must be at least 1", []})}

        {k, _rest} ->
          {k, errors}
      end

    if length(errors) > 0 do
      render(conn, :home, form: Phoenix.Component.to_form(params, errors: errors))
    else
      %{embedding: query_tensor} = Nx.Serving.batched_run(Search.Embedding, search_text)
      fragments = Search.Fragment.knn_lookup(query_tensor, k: k)

      render(conn, :search, fragments: fragments)
    end
  end
end
