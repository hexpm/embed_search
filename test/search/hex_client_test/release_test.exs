defmodule Search.HexClientTest.ReleaseTest do
  use ExUnit.Case, async: true

  alias Search.HexClient.Release

  describe "latest/1" do
    test "when given no prerelease entries, returns the release with largest version" do
      releases = [
        %Release{version: Version.parse!("1.2.3")},
        %Release{version: Version.parse!("2.1.3")},
        %Release{version: Version.parse!("1.4.3")}
      ]

      assert Release.latest(releases).version == Version.parse!("2.1.3")
    end

    test "when given only prerelease entries, returns the prerelease with largest version" do
      releases = [
        %Release{version: Version.parse!("1.2.3-rc1")},
        %Release{version: Version.parse!("2.1.3-rc2")},
        %Release{version: Version.parse!("1.4.3-rc1")}
      ]

      assert Release.latest(releases).version == Version.parse!("2.1.3-rc2")
    end

    test "when given mixed release and prerelease entries, returns the release with largest version" do
      releases = [
        %Release{version: Version.parse!("1.2.3")},
        %Release{version: Version.parse!("2.1.3")},
        %Release{version: Version.parse!("4.4.3-rc1")}
      ]

      assert Release.latest(releases).version == Version.parse!("2.1.3")
    end

    test "when given an empty list, returns nil" do
      assert is_nil(Release.latest([]))
    end
  end
end
