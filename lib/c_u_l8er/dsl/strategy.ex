
defmodule CUL8er.DSL.Strategy do
  @moduledoc """
  Strategy layer DSL - defines WHEN/HOW to deploy.

  Provides macros for deployment approaches, health checks, and rollback strategies.
  """

  @doc """
  Configures the deployment strategy.

  ## Examples

      strategy do
        approach :rolling
        batch_size 1

        healthcheck do
          endpoint "http://localhost:4000/health"
          interval seconds: 10
          retries 3
        end

        rollback do
          on_failure :automatic
          snapshot true
        end
      end
  """
  defmacro strategy(do: block) do
    quote do
      @strategy_config %{}
      unquote(block)
      strategy_config = @strategy_config
      @strategy_config nil
      @strategy strategy_config
    end
  end

  @doc """
  Sets the deployment approach.

  ## Options
  - `:rolling` - Rolling deployment (default)
  - `:blue_green` - Blue-green deployment
  - `:canary` - Canary deployment
  """
  defmacro approach(type) do
    quote do
      @strategy_config Map.put(@strategy_config || %{}, :approach, unquote(type))
    end
  end

  @doc """
  Sets the batch size for rolling deployments.
  """
  defmacro batch_size(size) do
    quote do
      @strategy_config Map.put(@strategy_config || %{}, :batch_size, unquote(size))
    end
  end

  @doc """
  Configures health checking.

  ## Examples

      healthcheck do
        endpoint "http://localhost:4000/health"
        interval seconds: 10
        timeout seconds: 5
        retries 3
      end
  """
  defmacro healthcheck(do: block) do
    quote do
      @healthcheck_config %{}
      unquote(block)
      healthcheck_config = @healthcheck_config
      @healthcheck_config nil
      @strategy_config Map.put(@strategy_config || %{}, :healthcheck, healthcheck_config)
    end
  end

  @doc """
  Sets the health check endpoint.
  """
  defmacro endpoint(url) do
    quote do
      @healthcheck_config Map.put(@healthcheck_config || %{}, :endpoint, unquote(url))
    end
  end

  @doc """
  Sets the health check interval.
  """
  defmacro interval(opts) do
    seconds = Keyword.get(opts, :seconds)

    quote do
      @healthcheck_config Map.put(@healthcheck_config || %{}, :interval_seconds, unquote(seconds))
    end
  end

  @doc """
  Sets the health check timeout.
  """
  defmacro timeout(opts) do
    seconds = Keyword.get(opts, :seconds)

    quote do
      @healthcheck_config Map.put(@healthcheck_config || %{}, :timeout_seconds, unquote(seconds))
    end
  end

  @doc """
  Sets the number of health check retries.
  """
  defmacro retries(count) do
    quote do
      @healthcheck_config Map.put(@healthcheck_config || %{}, :retries, unquote(count))
    end
  end

  @doc """
  Configures rollback settings.

  ## Examples

      rollback do
        on_failure :automatic
        snapshot true
        keep_versions 3
      end
  """
  defmacro rollback(do: block) do
    quote do
      @rollback_config %{}
      unquote(block)
      rollback_config = @rollback_config
      @rollback_config nil
      @strategy_config Map.put(@strategy_config || %{}, :rollback, rollback_config)
    end
  end

  @doc """
  Sets when to rollback.

  ## Options
  - `:automatic` - Rollback automatically on failure
  - `:manual` - Require manual rollback
  - `:never` - Never rollback automatically
  """
  defmacro on_failure(policy) do
    quote do
      @rollback_config Map.put(@rollback_config || %{}, :on_failure, unquote(policy))
    end
  end

  @doc """
  Enables or disables snapshots for rollback.
  """
  defmacro snapshot(enabled) do
    quote do
      @rollback_config Map.put(@rollback_config || %{}, :snapshot, unquote(enabled))
    end
  end

  @doc """
  Sets how many versions to keep for rollback.
  """
  defmacro keep_versions(count) do
    quote do
      @rollback_config Map.put(@rollback_config || %{}, :keep_versions, unquote(count))
    end
  end
end
