defmodule Search.HexClientTest do
  use ExUnit.Case, async: true

  alias Search.HexClient

  setup ctx do
    tmp_dir = ctx[:tmp_dir]

    if is_nil(tmp_dir) do
      {:ok, []}
    else
      test_tar_contents = [{~c"README.md", "# I am a README!"}]
      test_tar_path = Path.join(tmp_dir, "test_tar.tar.gz")

      :ok =
        :erl_tar.create(test_tar_path, test_tar_contents, [
          :compressed
        ])

      {:ok, %{test_tar: test_tar_path, test_tar_contents: test_tar_contents}}
    end
  end

  describe "get_releases/1" do
    test "when getting a response other than 200 OK, should fail gracefully" do
      Req.Test.stub(HexClient, fn conn ->
        Plug.Conn.send_resp(conn, 403, "Forbidden")
      end)

      assert HexClient.get_releases("test_package") == {:error, "HTTP 403"}
    end
  end

  describe "get_docs_tarball" do
    @tag :tmp_dir
    test "when given a release with documentation, should return contents of the archive", %{
      test_tar: test_tar,
      test_tar_contents: test_tar_contents
    } do
      Req.Test.stub(HexClient, fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/octet-stream", nil)
        |> Plug.Conn.send_file(200, test_tar)
      end)

      rel = %HexClient.Release{
        package_name: "test_package",
        version: Version.parse!("1.2.3")
      }

      assert HexClient.get_docs_tarball(rel) == {:ok, test_tar_contents}
    end

    test "when getting a response other than 200 OK, should fail gracefully" do
      Req.Test.stub(HexClient, fn conn ->
        Plug.Conn.send_resp(conn, 403, "Forbidden")
      end)

      rel = %HexClient.Release{
        package_name: "test_package",
        version: Version.parse!("1.2.3")
      }

      assert HexClient.get_docs_tarball(rel) == {:error, "HTTP 403"}
    end
  end
end
