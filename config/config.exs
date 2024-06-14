# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :search,
  ecto_repos: [Search.Repo],
  generators: [timestamp_type: :utc_datetime]

# Add types added by the pgvector-elixir extension to Postgrex
config :search, Search.Repo, types: Search.PostgrexTypes

# Register embedding providers
config :search, :embedding_providers,
  paraphrase_l3: {
    Search.Embeddings.BumblebeeProvider,
    serving_name: Search.Embeddings.ParaphraseL3,
    model: {:hf, "sentence-transformers/paraphrase-MiniLM-L3-v2"},
    embedding_size: 384,
    load_model_opts: [
      backend: EXLA.Backend
    ],
    serving_opts: [
      compile: [batch_size: 16, sequence_length: 512],
      defn_options: [compiler: EXLA]
    ]
  },
  paraphrase_albert_small: {
    Search.Embeddings.BumblebeeProvider,
    serving_name: Search.Embeddings.ParaphraseAlbertSmall,
    model: {:hf, "sentence-transformers/paraphrase-albert-small-v2"},
    embedding_size: 768,
    load_model_opts: [
      backend: EXLA.Backend
    ],
    serving_opts: [
      compile: [batch_size: 16, sequence_length: 100],
      defn_options: [compiler: EXLA]
    ]
  }

# Configures the endpoint
config :search, SearchWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: SearchWeb.ErrorHTML, json: SearchWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Search.PubSub,
  live_view: [signing_salt: "ra9Iks7b"]

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.17.11",
  search: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "3.4.0",
  search: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Configure the EXLA backend for Nx
config :nx, :default_backend, {EXLA.Backend, client: :host}

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
