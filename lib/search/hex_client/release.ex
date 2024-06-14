defmodule Search.HexClient.Release do
  defstruct [:package_name, :version]

  @type t :: %__MODULE__{
          package_name: String.t(),
          version: Version.t()
        }

  def latest(releases) do
    releases |> Enum.sort_by(& &1.version, {:desc, Version}) |> latest(nil)
  end

  defp latest([%__MODULE__{} = head | tail], latest_prerelease) do
    if head.version.pre == [] do
      head
    else
      latest(tail, latest_prerelease || head)
    end
  end

  defp latest([], latest_prerelease), do: latest_prerelease
end
