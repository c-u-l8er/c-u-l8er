defmodule CUL8er.DSL.Configuration do
  @moduledoc """
  Configuration layer DSL - defines HOW resources are configured.

  Provides macros for limits, network, environment, storage, and deployment configuration.
  """

  @doc """
  Configures resource limits.

  ## Examples

      limits do
        cpu cores: 4
        memory gigabytes: 8
      end
  """
  defmacro limits(do: block) do
    quote do
      @limits_config %{}
      unquote(block)
      limits_config = @limits_config
      @limits_config nil
      @resource_config Map.put(@resource_config || %{}, :limits, limits_config)
    end
  end

  @doc """
  Sets CPU limits.
  """
  defmacro cpu(opts) do
    cores = Keyword.get(opts, :cores)

    quote do
      @limits_config Map.put(@limits_config || %{}, :cpu, %{cores: unquote(cores)})
    end
  end

  @doc """
  Sets memory limits.
  """
  defmacro memory(opts) do
    gb = Keyword.get(opts, :gigabytes)
    mb = Keyword.get(opts, :megabytes)
    memory = if gb, do: gb * 1024 * 1024 * 1024, else: mb * 1024 * 1024

    quote do
      @limits_config Map.put(@limits_config || %{}, :memory, %{bytes: unquote(memory)})
    end
  end

  @doc """
  Configures network settings.

  ## Examples

      network do
        expose port: 4000, as: 443, protocol: :https
      end
  """
  defmacro network(do: block) do
    quote do
      @network_config %{}
      unquote(block)
      network_config = @network_config
      @network_config nil
      @resource_config Map.put(@resource_config || %{}, :network, network_config)
    end
  end

  @doc """
  Exposes a port from the container.

  ## Options
  - `port`: Internal port number
  - `as`: External port number (optional)
  - `protocol`: :http, :https, :tcp, :udp (default :tcp)
  """
  defmacro expose(opts) do
    port = Keyword.fetch!(opts, :port)
    as = Keyword.get(opts, :as, port)
    protocol = Keyword.get(opts, :protocol, :tcp)

    quote do
      @network_config Map.put(@network_config || %{}, :expose, %{
                        internal_port: unquote(port),
                        external_port: unquote(as),
                        protocol: unquote(protocol)
                      })
    end
  end

  @doc """
  Configures environment variables.

  ## Examples

      environment do
        set :MIX_ENV, "prod"
        secret :DATABASE_URL, from: :system
      end
  """
  defmacro environment(do: block) do
    quote do
      @environment_config []
      unquote(block)
      environment_config = @environment_config
      @environment_config nil
      @resource_config Map.put(@resource_config || %{}, :environment, environment_config)
    end
  end

  @doc """
  Sets a regular environment variable.
  """
  defmacro set(key, value) do
    quote do
      @environment_config [
        @environment_config || [],
        %{key: unquote(key), value: unquote(value), type: :plain}
      ]
    end
  end

  @doc """
  Sets a secret environment variable.
  """
  defmacro secret(key, opts) do
    from = Keyword.fetch!(opts, :from)
    path = Keyword.get(opts, :key) || Keyword.get(opts, :path)

    quote do
      @environment_config [
        @environment_config || [],
        %{key: unquote(key), from: unquote(from), path: unquote(path), type: :secret}
      ]
    end
  end

  @doc """
  Configures storage and volumes.

  ## Examples

      storage do
        volume :data, mount: "/var/lib/postgresql/data", writable: true
      end
  """
  defmacro storage(do: block) do
    quote do
      @storage_config []
      unquote(block)
      storage_config = @storage_config
      @storage_config nil
      @resource_config Map.put(@resource_config || %{}, :storage, storage_config)
    end
  end

  @doc """
  Defines a volume mount.
  """
  defmacro volume(name, opts) do
    mount = Keyword.fetch!(opts, :mount)
    writable = Keyword.get(opts, :writable, false)

    quote do
      @storage_config [
        @storage_config || [],
        %{
          name: unquote(name),
          mount_point: unquote(mount),
          writable: unquote(writable)
        }
      ]
    end
  end

  @doc """
  Configures deployment settings.

  ## Examples

      deploy release: :my_app, version: "1.0.0"
  """
  defmacro deploy(opts) do
    quote do
      @resource_config Map.put(@resource_config || %{}, :deploy, unquote(opts))
    end
  end
end
