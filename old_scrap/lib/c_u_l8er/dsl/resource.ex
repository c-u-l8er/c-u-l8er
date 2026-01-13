defmodule CUL8er.DSL.Resource do
  @moduledoc """
  Represents a resource in the infrastructure topology.

  A resource can be a container, VM, or other deployable unit.
  """

  @type t :: %__MODULE__{
          name: atom(),
          type: :container | :vm,
          host: atom(),
          image: String.t(),
          config: map(),
          tags: [String.t()]
        }

  defstruct [
    :name,
    :type,
    :host,
    :image,
    config: %{},
    tags: []
  ]

  @doc """
  Creates a new Resource struct.
  """
  def new(name, type, host, opts \\ []) do
    %__MODULE__{
      name: name,
      type: type,
      host: host,
      image: opts[:image],
      config: opts[:config] || %{},
      tags: opts[:tags] || []
    }
  end
end
