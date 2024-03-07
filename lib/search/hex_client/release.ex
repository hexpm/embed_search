defmodule Search.HexClient.Release do
  defstruct [:package_name, :version, :has_docs]

  @type t :: %__MODULE__{
          package_name: String.t(),
          version: Version.t(),
          has_docs: boolean()
        }
end
