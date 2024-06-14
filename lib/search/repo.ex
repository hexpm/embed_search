defmodule Search.Repo do
  use Ecto.Repo,
    otp_app: :search,
    adapter: Ecto.Adapters.Postgres

  def transaction_with(fun, options \\ []) when is_function(fun, 0) and is_list(options) do
    transaction(
      fn ->
        case fun.() do
          {:ok, result} ->
            result

          {:error, reason} ->
            rollback(reason)

          other ->
            raise ArgumentError,
                  "expected to return {:ok, _} or {:error, _}, got: #{inspect(other)}"
        end
      end,
      options
    )
  end
end
