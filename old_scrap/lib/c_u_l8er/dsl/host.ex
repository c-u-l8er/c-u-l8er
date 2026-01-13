defmodule CUL8er.DSL.Host do
  @moduledoc """
  Represents a host in the infrastructure topology.

  A host can be a local machine, remote server, or cloud instance.
  """

  @type t :: %__MODULE__{
          name: atom(),
          address: String.t(),
          platform: atom(),
          credentials: map(),
          tags: [String.t()]
        }

  defstruct [
    :name,
    :address,
    :platform,
    :credentials,
    tags: []
  ]

  @doc """
  Creates a new Host struct.
  """
  def new(name, opts \\ []) do
    %__MODULE__{
      name: name,
      address: opts[:address],
      platform: opts[:platform] || :icusos,
      credentials: opts[:credentials] || %{},
      tags: opts[:tags] || []
    }
  end
end
