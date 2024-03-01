defmodule Search.ExDocParserTest do
  alias Search.{ExDocParser, TestHelpers}
  use ExUnit.Case, async: true

  @dummy_items [%{"doc" => "dummy doc"}, %{"doc" => "another dummy"}]
  @invalid_json ~c"{\"items\": oops this is invalid}"

  setup ctx do
    tmp_dir = ctx[:tmp_dir]

    if is_nil(tmp_dir) do
      {:ok, []}
    else
      search_data_content =
        "searchData=#{JSON.encode!(%{"items" => @dummy_items})}"

      search_data_path = "dist/search_data-12ABCDEF.js"

      test_tar =
        TestHelpers.make_targz(tmp_dir, search_data_content, search_data_path)

      {:ok,
       %{
         test_tar: test_tar,
         search_data_path: search_data_path,
         search_data_content: search_data_content
       }}
    end
  end

  describe "untar_exdoc_release/1" do
    test "when given no options, should raise" do
      assert_raise ArgumentError, fn -> ExDocParser.untar_exdoc_release() end
    end

    test "when given both :file and :binary, should raise" do
      assert_raise ArgumentError, fn ->
        ExDocParser.untar_exdoc_release(file: :something, binary: :something)
      end
    end

    @tag :tmp_dir
    test "should produce the same results for a file input and its binary contents", %{
      test_tar: test_tar
    } do
      fd = File.open!(test_tar, [:compressed, :binary])
      contents = IO.binread(fd, :eof)

      # reset the file descriptor
      :ok = File.close(fd)
      fd = File.open!(test_tar, [:compressed, :binary])

      file_res = ExDocParser.untar_exdoc_release(file: fd)
      binary_res = ExDocParser.untar_exdoc_release(binary: contents)

      :ok = File.close(fd)

      assert file_res == binary_res
    end

    @tag :tmp_dir
    test "should successfully extract contents of a well-formed tarball", %{
      test_tar: test_tar,
      search_data_path: search_data_path,
      search_data_content: search_data_content
    } do
      file = File.open!(test_tar, [:compressed, :binary])

      assert {:ok, [{to_charlist(search_data_path), search_data_content}]} ==
               ExDocParser.untar_exdoc_release(file: file)

      File.close(file)
    end

    test "should fail for non-tar data" do
      assert match?(
               {:error, _erl_tar_error},
               ExDocParser.untar_exdoc_release(binary: "I am not a tarball!")
             )
    end
  end

  describe "extract_search_data/1" do
    test "should extract search data for archives with the right format" do
      untar = [
        {~c"dist/search_data-AF57AB42.js",
         "searchData=#{JSON.encode!(%{"items" => @dummy_items})}"}
      ]

      assert {:ok, @dummy_items} = ExDocParser.extract_search_data(untar)
    end

    test "should fail for archives with no dist/search_data-XXXXXXXX.js files" do
      untar = [
        {~c"search_data-ABCDEF12.js", "not this"},
        {~c"not_dist/search_data-12345678.js", "not this either"}
      ]

      assert {:error,
              "Search data not found, package documentation is not in a supported format."} ==
               ExDocParser.extract_search_data(untar)
    end

    test "should fail for search data not starting with the \"searchData=\" prefix" do
      untar = [
        {~c"dist/search_data-AF57AB42.js", JSON.encode!(%{"items" => @dummy_items})}
      ]

      assert {:error, "Search data content does not start with \"searchData=\"."} ==
               ExDocParser.extract_search_data(untar)
    end

    test "should fail for search data with invalid JSON" do
      untar = [
        {~c"dist/search_data-AF57AB42.js", "searchData=#{@invalid_json}"}
      ]

      assert {:error, "Search data content is not proper JSON"} ==
               ExDocParser.extract_search_data(untar)
    end

    test "should fail for search data with valid JSON, but no \"items\" key" do
      untar = [
        {~c"dist/search_data-AF57AB42.js", "searchData=#{JSON.encode!(@dummy_items)}"}
      ]

      assert {:error, "Search data content does not contain the key \"items\""} ==
               ExDocParser.extract_search_data(untar)
    end
  end
end
