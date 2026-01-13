
defmodule CUL8er.DSL.Cluster do
  @moduledoc """
  Cluster layer DSL - defines HOW nodes communicate.

  Provides macros for cluster configuration, node discovery, and communication settings.
  """

  @doc """
  Configures clustering for the topology.

  ## Examples

      cluster :app_cluster do
        nodes [:web_1, :web_2, :web_3]
        discovery strategy: Cluster.Strategy.Epmd
        cookie from: :system, key: "RELEASE_COOKIE"
      end
  """
  defmacro cluster(name, do: block) do
    quote do
      @cluster_config %{name: unquote(name)}
      unquote(block)
      cluster_config = @cluster_config
      @cluster_config nil
      @cluster cluster_config
    end
  end

  @doc """
  Sets the nodes that should be part of the cluster.
  """
  defmacro nodes(node_list) do
    quote do
      @cluster_config Map.put(@cluster_config || %{}, :nodes, unquote(node_list))
    end
  end

  @doc """
  Configures node discovery strategy.

  ## Examples

      discovery strategy: Cluster.Strategy.Epmd
      discovery strategy: Cluster.Strategy.Kubernetes, kubernetes_node_basename: "my_app"
  """
  defmacro discovery(opts) do
    strategy = Keyword.fetch!(opts, :strategy)
    extra_opts = Keyword.delete(opts, :strategy)

    quote do
      @cluster_config Map.put(@cluster_config || %{}, :discovery, %{
                        strategy: unquote(strategy),
                        options: unquote(extra_opts)
                      })
    end
  end

  @doc """
  Sets the Erlang cookie for the cluster.

  ## Examples

      cookie "my_secret_cookie"
      cookie from: :system, key: "RELEASE_COOKIE"
      cookie from: :secret_store, key: "cluster/cookie"
  """
  defmacro cookie(opts) do
    case opts do
      cookie when is_binary(cookie) ->
        quote do
          @cluster_config Map.put(@cluster_config || %{}, :cookie, %{
                            value: unquote(cookie),
                            type: :plain
                          })
        end

      opts when is_list(opts) ->
        from = Keyword.fetch!(opts, :from)
        key = Keyword.get(opts, :key) || Keyword.get(opts, :path)

        quote do
          @cluster_config Map.put(@cluster_config || %{}, :cookie, %{
                            from: unquote(from),
                            key: unquote(key),
                            type: :reference
                          })
        end
    end
  end

  @doc """
  Configures cluster communication settings.

  ## Examples

      communication do
        port 4369
        tls_enabled true
      end
  """
  defmacro communication(do: block) do
    quote do
      @communication_config %{}
      unquote(block)
      communication_config = @communication_config
      @communication_config nil
      @cluster_config Map.put(@cluster_config || %{}, :communication, communication_config)
    end
  end

  @doc """
  Sets the cluster communication port.
  """
  defmacro port(port_number) do
    quote do
      @communication_config Map.put(@communication_config || %{}, :port, unquote(port_number))
    end
  end

  @doc """
  Enables or disables TLS for cluster communication.
  """
  defmacro tls_enabled(enabled) do
    quote do
      @communication_config Map.put(@communication_config || %{}, :tls_enabled, unquote(enabled))
    end
  end
end
