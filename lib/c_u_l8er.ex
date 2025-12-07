defmodule CUL8er do
  @moduledoc """
  Main entry point for C U L8er DSL.

  Provides the `topology` macro and imports all DSL modules.
  """

  defmacro __using__(_opts) do
    quote do
      import CUL8er
      import CUL8er.DSL.Infrastructure
      import CUL8er.DSL.Configuration
      import CUL8er.DSL.Strategy
      import CUL8er.DSL.Cluster
    end
  end

  @doc """
  Defines a topology with the given name.

  ## Examples

      topology :production do
        host :web do
          address "prod.example.com"
        end

        resource :app, type: :container, on: :web do
          from_image "images:alpine/3.19"
        end
      end
  """
  defmacro topology(name, do: block) do
    quote do
      @topologies unquote(name)

      defmodule __MODULE__.Topology do
        @moduledoc false

        # Import DSL modules for this submodule
        import CUL8er.DSL.Infrastructure
        import CUL8er.DSL.Configuration
        import CUL8er.DSL.Strategy
        import CUL8er.DSL.Cluster

        # Initialize module attributes for DSL collection
        @hosts %{}
        @resources %{}
        @strategy %{}
        @cluster %{}

        def name, do: unquote(name)

        unquote(block)

        # Collect all defined elements
        def topology do
          %{
            name: unquote(name),
            hosts: @hosts || %{},
            resources: @resources || %{},
            strategy: @strategy || %{},
            cluster: @cluster || %{}
          }
        end
      end

      # Define a function to access this topology
      def unquote(name)() do
        __MODULE__.Topology.topology()
      end
    end
  end
end
