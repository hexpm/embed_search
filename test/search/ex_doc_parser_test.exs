defmodule Search.ExDocParserTest do
  alias Search.ExDocParser
  use ExUnit.Case, async: true

  @dummy_items [%{"doc" => "dummy doc"}, %{"doc" => "another dummy"}]
  @invalid_json ~c"{\"items\": oops this is invalid}"

  setup ctx do
    tmp_dir = ctx[:tmp_dir]

    if is_nil(tmp_dir) do
      {:ok, []}
    else
      no_items_key = JSON.encode!(@dummy_items)

      with_items_key =
        JSON.encode!(%{"items" => @dummy_items})

      with_prefix_with_items_key =
        "searchData=#{with_items_key}"

      with_prefix_no_items_key =
        "searchData=#{no_items_key}"

      no_items_key_tar = make_targz(tmp_dir, no_items_key, "dist/search_data-ABCDEF.js")
      with_items_key_tar = make_targz(tmp_dir, with_items_key, "dist/search_data-ABCDEF.js")

      with_prefix_with_items_key_tar =
        make_targz(tmp_dir, with_prefix_with_items_key, "dist/search_data-ABCDEF.js")

      with_prefix_no_items_key_tar =
        make_targz(tmp_dir, with_prefix_no_items_key, "dist/search_data-ABCDEF.js")

      no_search_data =
        make_targz(tmp_dir, with_prefix_with_items_key, "dist/not_search_data-ABCDEF.js")

      invalid_json =
        make_targz(tmp_dir, "searchData=#{@invalid_json}", "dist/search_data-ABCDEF.js")

      {:ok,
       %{
         no_prefix: %{
           no_items_key: no_items_key_tar,
           with_items_key: with_items_key_tar
         },
         with_prefix: %{
           no_items_key: with_prefix_no_items_key_tar,
           with_items_key: with_prefix_with_items_key_tar
         },
         wrong_format: no_search_data,
         invalid_json: invalid_json
       }}
    end
  end

  describe "get_documentation/1" do
    test "when given no options, should raise" do
      assert_raise ArgumentError, fn -> ExDocParser.get_documentation() end
    end

    test "when given both :file and :binary, should raise" do
      assert_raise ArgumentError, fn ->
        ExDocParser.get_documentation(file: :something, binary: :something)
      end
    end

    @tag :tmp_dir
    test "should produce the same results for a file input and its binary contents", %{
      with_prefix: %{with_items_key: file}
    } do
      fd = File.open!(file, [:compressed, :binary])
      contents = IO.binread(fd, :eof)

      # reset the file descriptor
      :ok = File.close(fd)
      fd = File.open!(file, [:compressed, :binary])

      file_res = ExDocParser.get_documentation(file: fd)
      binary_res = ExDocParser.get_documentation(binary: contents)

      :ok = File.close(fd)

      assert file_res == binary_res
    end

    @tag :tmp_dir
    test "should successfully extract contents of the search data for a well-formed tarball", %{
      with_prefix: %{with_items_key: file}
    } do
      file = File.open!(file, [:compressed, :binary])

      assert {:ok, @dummy_items} == ExDocParser.get_documentation(file: file)

      File.close(file)
    end

    test "should fail for non-tar data" do
      assert match?(
               {:error, _erl_tar_error},
               ExDocParser.get_documentation(binary: "I am not a tarball!")
             )
    end

    @tag :tmp_dir
    test "should fail for archives with no `dist/search_data*` files", %{wrong_format: file} do
      file = File.open!(file, [:compressed, :binary])

      assert {:error,
              "Search data not found, package documentation is not in a supported format."} ==
               ExDocParser.get_documentation(file: file)

      File.close(file)
    end

    @tag :tmp_dir
    test "should fail for search data not starting with the \"searchData=\" prefix", %{
      no_prefix: %{with_items_key: file}
    } do
      file = File.open!(file, [:compressed, :binary])

      assert {:error, "Search data content does not start with \"searchData=\"."} ==
               ExDocParser.get_documentation(file: file)

      File.close(file)
    end

    @tag :tmp_dir
    test "should fail for search data with invalid JSON", %{invalid_json: file} do
      file = File.open!(file, [:compressed, :binary])

      assert {:error, "Search data content is not proper JSON"} ==
               ExDocParser.get_documentation(file: file)

      File.close(file)
    end

    @tag :tmp_dir
    test "should fail for search data with valid JSON, but no \"items\" key", %{
      with_prefix: %{no_items_key: file}
    } do
      file = File.open!(file, [:compressed, :binary])

      assert {:error, "Search data content does not contain the key \"items\""} ==
               ExDocParser.get_documentation(file: file)

      File.close(file)
    end
  end

  defp make_targz(tmp, search_data, name_in_archive) do
    filename =
      :crypto.hash(:md5, search_data <> name_in_archive)
      |> Base.encode64(padding: false)

    filename = "#{filename}.tar.gz"

    path = Path.join(tmp, filename)

    {:ok, tarball} = :erl_tar.open(path, [:write, :compressed])
    :ok = :erl_tar.add(tarball, {to_charlist(name_in_archive), search_data}, [])
    :ok = :erl_tar.close(tarball)

    path
  end
end
