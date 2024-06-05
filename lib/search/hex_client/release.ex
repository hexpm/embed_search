defmodule Search.HexClient.Release do
  defstruct [:package_name, :version]

  @type t :: %__MODULE__{
          package_name: String.t(),
          version: Version.t()
        }

  def latest([] = _releases), do: nil

  def latest([%__MODULE__{} = releases_head | releases_tail] = _releases) do
    if releases_head.version.pre != [] do
      latest(releases_tail, nil, releases_head, true)
    else
      latest(releases_tail, releases_head, nil, false)
    end
  end

  defp latest([], latest_release, latest_pre, all_pre?) do
    if all_pre? do
      latest_pre
    else
      latest_release
    end
  end

  defp latest(
         [%__MODULE__{version: head_version} = releases_head | releases_tail],
         latest_release,
         latest_pre,
         all_pre?
       ) do
    case head_version do
      %Version{pre: []} ->
        if is_nil(latest_release) or Version.compare(head_version, latest_release.version) == :gt do
          # there is a new latest release, we can be sure there are no longer only prerelease entries
          latest(releases_tail, releases_head, latest_pre, false)
        else
          # not a new latest release, but we are sure there is at least one non-prerelease entry
          latest(releases_tail, latest_release, latest_pre, false)
        end

      _ ->
        if is_nil(latest_pre) or Version.compare(head_version, latest_pre.version) == :gt do
          # there is a new latest prerelease
          latest(releases_tail, latest_release, releases_head, all_pre?)
        else
          # not a new latest prerelease, but a prerelease nonetheless
          latest(releases_tail, latest_release, latest_pre, all_pre?)
        end
    end
  end
end
