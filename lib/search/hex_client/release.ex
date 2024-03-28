defmodule Search.HexClient.Release do
  defstruct [:package_name, :version]

  @type t :: %__MODULE__{
          package_name: String.t(),
          version: Version.t()
        }
end
