defmodule Search.TestHelpers do
  def make_targz(tmp_dir, data, name_in_archive) do
    filename =
      :crypto.hash(:md5, data <> name_in_archive)
      |> Base.encode16()

    filename = "#{filename}.tar.gz"

    path = Path.join(tmp_dir, filename)

    {:ok, tarball} = :erl_tar.open(path, [:write, :compressed])
    :ok = :erl_tar.add(tarball, {to_charlist(name_in_archive), data}, [])
    :ok = :erl_tar.close(tarball)

    path
  end
end
