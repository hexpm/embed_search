defmodule Search.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def embedding_models do
    Application.fetch_env!(:search, :embedding_providers)
  end

  @impl true
  def start(_type, _args) do
    children =
      [
        SearchWeb.Telemetry,
        Search.Repo,
        {DNSCluster, query: Application.get_env(:search, :dns_cluster_query) || :ignore},
        {Phoenix.PubSub, name: Search.PubSub}
      ] ++
        Enum.map(embedding_models(), fn {_, {provider, opts}} -> provider.child_spec(opts) end) ++
        [
          # Start to serve requests, typically the last entry
          SearchWeb.Endpoint
        ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Search.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    SearchWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
