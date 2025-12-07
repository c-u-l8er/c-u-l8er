defmodule CUL8er.DSL.Infrastructure do
  @moduledoc """
  Infrastructure layer DSL - defines WHAT exists.

  Provides macros for `host` and `resource` definitions.
  """

  @doc """
  Defines a host in the topology.

  ## Examples

      host :web_server do
        address "prod.example.com"
        platform :icusos
        credentials ssh: [user: "deploy", key: "~/.ssh/id_rsa"]
      end
  """
  defmacro host(name, do: block) do
    quote do
      # Initialize config accumulator
      @host_config %{}

      # Execute the block to collect configuration
      unquote(block)

      # Create the host struct with collected config
      host_config = @host_config
      # Reset for next host
      @host_config nil

      @hosts Map.put(
               @hosts || %{},
               unquote(name),
               struct(CUL8er.DSL.Host, Map.put(host_config, :name, unquote(name)))
             )
    end
  end

  @doc """
  Sets the address of a host.
  """
  defmacro address(value) do
    quote do
      @host_config Map.put(@host_config || %{}, :address, unquote(value))
    end
  end

  @doc """
  Sets the platform of a host.
  """
  defmacro platform(value) do
    quote do
      @host_config Map.put(@host_config || %{}, :platform, unquote(value))
    end
  end

  @doc """
  Sets the credentials for a host.
  """
  defmacro credentials(value) do
    quote do
      @host_config Map.put(@host_config || %{}, :credentials, unquote(value))
    end
  end

  @doc """
  Defines a resource in the topology.

  ## Examples

      resource :web, type: :container, on: :web_server do
        from_image "images:alpine/3.19"
      end
  """
  defmacro resource(name, opts, do: block) do
    type = Keyword.fetch!(opts, :type)
    on_host = Keyword.fetch!(opts, :on)

    quote do
      # Initialize config accumulator
      @resource_config %{}

      # Execute the block to collect configuration
      unquote(block)

      # Create the resource struct with collected config
      resource_config = @resource_config
      # Reset for next resource
      @resource_config nil

      # Separate image from other config
      image = Map.get(resource_config, :image)
      other_config = Map.delete(resource_config, :image)

      @resources Map.put(
                   @resources || %{},
                   unquote(name),
                   struct(CUL8er.DSL.Resource, %{
                     name: unquote(name),
                     type: unquote(type),
                     host: unquote(on_host),
                     image: image,
                     config: other_config
                   })
                 )
    end
  end

  @doc """
  Sets the image for a resource.
  """
  defmacro from_image(value) do
    quote do
      @resource_config Map.put(@resource_config || %{}, :image, unquote(value))
    end
  end
end
