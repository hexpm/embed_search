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
        |> compute_splits(max_size, 0, nil, [])
        |> split_binary(text)
    end
  end

  @doc """
  Recreates the original text from a list of chunks.
  """
  def recombine(chunks), do: Enum.join(chunks)

  defp split_binary([], ""), do: []

  defp split_binary([split_size | splits_tail], string) do
    <<chunk::binary-size(^split_size), rest::binary>> = string
    [chunk | split_binary(splits_tail, rest)]
  end

  defp compute_splits("", _, size, _, sizes), do: Enum.reverse(sizes, [size])

  defp compute_splits(
         string,
         max_size,
         size,
         size_until_word,
         sizes
       ) do
    {grapheme, string} = String.next_grapheme(string)
    grapheme_size = byte_size(grapheme)

    if size + grapheme_size > max_size do
      if size_until_word do
        # Split before the current unfinished word
        next = size - size_until_word
        compute_splits(string, max_size, next + grapheme_size, nil, [size_until_word | sizes])
      else
        # The current chunk has a single word, just split it
        compute_splits(string, max_size, grapheme_size, nil, [size | sizes])
      end
    else
      new_size = size + grapheme_size
      size_until_word = if whitespace?(grapheme), do: new_size, else: size_until_word
      compute_splits(string, max_size, new_size, size_until_word, sizes)
    end
  end

  defp whitespace?(grapheme), do: grapheme =~ ~r/\s/
end
