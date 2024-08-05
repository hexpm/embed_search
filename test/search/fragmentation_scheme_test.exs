defmodule Search.FragmentationSchemeTest do
  alias Search.FragmentationScheme
  use ExUnit.Case, async: true

  describe "split/2" do
    test "when given an empty string, returns empty list" do
      assert FragmentationScheme.split("") == []
    end

    test "when given a string which satisfies the size constraint, returns a singleton list with that string" do
      str = "short string"

      assert FragmentationScheme.split(str, max_size: 100) == [str]
    end

    test "when given a string that is too long and splitting along whitespace is possible, splits the string" do
      str = "some words and some more words"

      assert FragmentationScheme.split(str, max_size: 15) == [
               "some words and ",
               "some more words"
             ]
    end

    test "when splitting along whitespace, respects non-space whitespace characters" do
      str = "word\nword\tword\u{2003}word"

      assert FragmentationScheme.split(str, max_size: 7) == [
               "word\n",
               "word\t",
               "word\u{2003}",
               "word"
             ]
    end

    test "when splitting along whitespace and the text starts with whitespace, the whitespace characters are prepended to the first fragment" do
      str = "    words and some more words"

      assert FragmentationScheme.split(str, max_size: 15) == [
               "    words and ",
               "some more words"
             ]
    end

    test "when cannot split along whitespace, splits along grapheme boundaries" do
      str1 = "asdfghjkl"

      assert FragmentationScheme.split(str1, max_size: 5) == [
               "asdfg",
               "hjkl"
             ]

      # the "g" has a bunch of diacritics, which means the grapheme is 4 codepoints / 7 bytes long
      str2 = "asdfg\u{0300}\u{0322}\u{0342}hjkl"

      assert FragmentationScheme.split(str2, max_size: 7) == [
               "asdf",
               "g\u{0300}\u{0322}\u{0342}",
               "hjkl"
             ]
    end
  end

  describe "recombine/1" do
    test "recreates the original text" do
      str = """
      Lorem ipsum dolor sit amet, consectetur adipiscing elit.

      Phasellus convallis libero at lectus vestibulum, sit amet mattis leo tempor.

      Aenean pulvinar purus ac euismod accumsan.

      Cras finibus risus laoreet neque condimentum, nec hendrerit justo blandit.

      Sed vitae orci ut odio pellentesque cursus.
      """

      split = FragmentationScheme.split(str, max_size: 100)

      assert FragmentationScheme.recombine(split) == str
    end
  end
end
