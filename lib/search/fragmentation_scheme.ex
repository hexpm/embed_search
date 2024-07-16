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
      nil -> [text]
      max_size -> do_split(text, [], max_size)
    end
  end

  def recombine(chunks), do: Enum.join(chunks)

  defp do_split("", acc, _max_size), do: Enum.reverse(acc)

  defp do_split(text, acc, max_size) do
    # capture the next word along with trailing whitespace and leading whitespace, if any
    [next_word] =
      Regex.run(~r/^([\s]*[^\s]+\s+)[^\s]*/, text, capture: :all_but_first) ||
        [text]

    word_chunks =
      if byte_size(next_word) > max_size do
        split_word("", next_word, [], max_size)
      else
        [next_word]
      end

    next_text = binary_slice(text, byte_size(next_word)..-1//1)

    case {word_chunks, acc} do
      {_, []} ->
        do_split(next_text, word_chunks, max_size)

      {[single_word], [acc_head | acc_tail]} ->
        # we can try extending the last word in accumulator
        if byte_size(acc_head) + byte_size(single_word) <= max_size do
          do_split(next_text, [acc_head <> single_word | acc_tail], max_size)
        else
          do_split(next_text, [single_word | acc], max_size)
        end

      _ ->
        # the word had to be split into chunks; there is no need to extend the last word in accumulator
        do_split(next_text, word_chunks ++ acc, max_size)
    end
  end

  defp split_word("", "", acc, _max_size), do: acc
  defp split_word(chunk, "", acc, _max_size), do: [chunk | acc]

  defp split_word(current_chunk, word_rest, acc, max_size) do
    {next_graph, word_rest} = String.next_grapheme(word_rest)

    if byte_size(current_chunk) + byte_size(next_graph) <= max_size do
      # we can continue building the current chunk of the word
      split_word(current_chunk <> next_graph, word_rest, acc, max_size)
    else
      # the next grapheme would bring the chunk over the max size, push to accumulator
      split_word(next_graph, word_rest, [current_chunk | acc], max_size)
    end
  end
end
