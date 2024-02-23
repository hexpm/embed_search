defmodule Search.Embedding do
  @moduledoc """
  A `GenServer` providing the model and tokenizer for text embedding using the Sentence
  Transformers `paraphrase-MiniLM-L3-v2` model.
  """

  @embedding_size 384
  @model_repo {:hf, "sentence-transformers/paraphrase-MiniLM-L3-v2"}

  use GenServer
  require Logger

  def embedding_size, do: @embedding_size

  def start_link(opts \\ []), do: GenServer.start_link(__MODULE__, :unused_arg, opts)

  @impl true
  def init(_) do
    {:ok, %{model: model, params: params}} = Bumblebee.load_model(@model_repo)
    {:ok, tokenizer} = Bumblebee.load_tokenizer(@model_repo)

    {:ok, {model, params, tokenizer}}
  end

  def tokenizer, do: GenServer.call(__MODULE__, :get_tokenizer)
  def model, do: GenServer.call(__MODULE__, :get_model)

  @impl true
  def handle_call(:get_tokenizer, _from, {_model, _params, tokenizer} = state) do
    {:reply, tokenizer, state}
  end

  @impl true
  def handle_call(:get_model, _from, {model, params, _tokenizer} = state) do
    {:reply, {model, params}, state}
  end
end
