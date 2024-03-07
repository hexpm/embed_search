defmodule Search.ExDocParserTest do
  alias Search.ExDocParser
  use ExUnit.Case, async: true

  @dummy_items [%{"doc" => "dummy doc"}, %{"doc" => "another dummy"}]
  @invalid_json ~c"{\"items\": oops this is invalid}"

  describe "extract_search_data/1" do
    test "should extract search data for archives with the right format" do
      untar = [
        {~c"dist/search_data-AF57AB42.js",
         "searchData=#{Jason.encode!(%{"items" => @dummy_items})}"}
      ]

      assert ExDocParser.extract_search_data(untar) == {:ok, @dummy_items}
    end

    test "should fail for archives with no dist/search_data-XXXXXXXX.js files" do
      untar = [
        {~c"search_data-ABCDEF12.js", "not this"},
        {~c"not_dist/search_data-12345678.js", "not this either"}
      ]

      assert ExDocParser.extract_search_data(untar) ==
               {:error,
                "Search data not found, package documentation is not in a supported format."}
    end

    test "should fail for search data not starting with the \"searchData=\" prefix" do
      untar = [
        {~c"dist/search_data-AF57AB42.js", Jason.encode!(%{"items" => @dummy_items})}
      ]

      assert ExDocParser.extract_search_data(untar) ==
               {:error, "Search data content does not start with \"searchData=\"."}
    end

    test "should fail for search data with invalid JSON" do
      untar = [
        {~c"dist/search_data-AF57AB42.js", "searchData=#{@invalid_json}"}
      ]

      assert ExDocParser.extract_search_data(untar) ==
               {:error, "Search data content is invalid JSON"}
    end
  end
end
