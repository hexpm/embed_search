defmodule Search.FragmentationScheme do
  @doc """
  Splits a binary into multiple binaries that satisfy limitations specified by opts.

  If possible, splits the text on whitespace to preserve words. If that is impossible, splits text in between graphemes.

  Supported options:

  * `:max_size` - maximum byte_size of the output binaries. The output binaries may have size less or equal to that
    value, which also should guarantee the sequence length after tokenization will be bounded by this value.
  """
  def split(text, opts \\ [])
  def split("", _opts), do: []

  def split(text, opts) when is_binary(text) do
    case Keyword.get(opts, :max_size) do
      nil ->
        [text]

      max_size ->
        text
        |> compute_splits({0, 0}, 0, max_size, [])
        |> split_binary(text)
    end
  end

  def recombine(chunks), do: Enum.join(chunks)

  defp split_binary([], ""), do: []

  defp split_binary([split_size | splits_tail], string) do
    <<chunk::binary-size(^split_size), rest::binary>> = string
    [chunk | split_binary(splits_tail, rest)]
  end

  defp compute_splits("", {0, 0}, 0, _max_size, acc), do: Enum.reverse(acc)

  defp compute_splits("", {chunk_size, trailing_whitespace}, next_word, max_size, acc) do
    if chunk_size + trailing_whitespace + next_word <= max_size do
      compute_splits("", {0, 0}, 0, max_size, [chunk_size + trailing_whitespace + next_word | acc])
    else
      compute_splits("", {0, 0}, 0, max_size, [next_word, chunk_size + trailing_whitespace | acc])
    end
  end

  defp compute_splits(
         text,
         {current_chunk_size, trailing_whitespace_size},
         next_word_size,
         max_size,
         acc
       ) do
    {graph, text} = String.next_grapheme(text)
    graph_size = byte_size(graph)
    whole_chunk_size = current_chunk_size + trailing_whitespace_size

    if graph =~ ~r/\s/ do
      # graph is whitespace
      if next_word_size == 0 do
        # we are still building the current chunk
        if whole_chunk_size + graph_size <= max_size do
          # we can append the whitespace graph to the current chunk
          compute_splits(
            text,
            {current_chunk_size, trailing_whitespace_size + graph_size},
            0,
            max_size,
            acc
          )
        else
          # we have to push the current chunk to the accumulator and start building the next one
          compute_splits(text, {0, graph_size}, 0, max_size, [whole_chunk_size | acc])
        end
      else
        # we are currently building a possible extension to the current chunk
        cond do
          whole_chunk_size + next_word_size + graph_size <= max_size ->
            # both the next word and the whitespace grapheme after it can fit within the max_size
            compute_splits(
              text,
              {
                whole_chunk_size + next_word_size,
                graph_size
              },
              0,
              max_size,
              acc
            )

          whole_chunk_size + next_word_size <= max_size ->
            # the next word can fit, but the whitespace grapheme after it cannot - the whitespace becomes the trailing
            # whitespace of the next chunk
            compute_splits(
              text,
              {0, graph_size},
              0,
              max_size,
              [whole_chunk_size + next_word_size | acc]
            )

          true ->
            # current chunk cannot be extended, the next word becomes the current word
            compute_splits(text, {next_word_size, graph_size}, 0, max_size, [
              whole_chunk_size | acc
            ])
        end
      end
    else
      # graph is not whitespace
      if next_word_size == 0 do
        # we are building the current chunk
        cond do
          trailing_whitespace_size == 0 && current_chunk_size + graph_size <= max_size ->
            # we are building the current word, so we append the grapheme to the word being built
            compute_splits(text, {current_chunk_size + graph_size, 0}, 0, max_size, acc)

          whole_chunk_size + graph_size <= max_size ->
            # the current word ended with whitespace, so we start building the next word candidate for extension
            compute_splits(
              text,
              {current_chunk_size, trailing_whitespace_size},
              graph_size,
              max_size,
              acc
            )

          true ->
            # the current word either has to be sliced in half, or the current chunk ends with whitespace,
            # so we can just push the current chunk onto the accumulator
            compute_splits(text, {graph_size, 0}, 0, max_size, [whole_chunk_size | acc])
        end
      else
        # we are building the next word candidate
        if whole_chunk_size + next_word_size + graph_size <= max_size do
          # we can continue building the next word
          compute_splits(
            text,
            {current_chunk_size, trailing_whitespace_size},
            next_word_size + graph_size,
            max_size,
            acc
          )
        else
          # the next word is too long to extend the current chunk
          compute_splits(text, {next_word_size + graph_size, 0}, 0, max_size, [
            whole_chunk_size | acc
          ])
        end
      end
    end
  end
end
