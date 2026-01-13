defmodule Mix.Tasks.CUL8er.Plan do
  @moduledoc """
  Plans changes for a C U L8er topology.

  Usage:
      mix c_u_l8er.plan <module> <topology>

  Examples:
      mix c_u_l8er.plan MyApp.Topology production
  """

  use Mix.Task

  @shortdoc "Plan changes for a C U L8er topology"

  def run(args) do
    case args do
      [module_name, topology_name] ->
        plan_topology(module_name, topology_name)

      _ ->
        Mix.shell().error("Usage: mix c_u_l8er.plan <module> <topology>")
        exit({:shutdown, 1})
    end
  end

  defp plan_topology(module_name, topology_name) do
    # Start required GenServers
    start_services()

    module = String.to_atom("Elixir.#{module_name}")
    topology_atom = String.to_atom(topology_name)

    case Code.ensure_loaded(module) do
      {:module, _} ->
        if function_exported?(module, topology_atom, 0) do
          topology_data = apply(module, topology_atom, [])

          Mix.shell().info(
            "Planning changes for topology #{topology_name} from #{module_name}..."
          )

          case CUL8er.Core.Executor.plan_changes(topology_atom, topology_data) do
            {:ok, plan} ->
              display_plan(plan)

            {:error, reason} ->
              Mix.shell().error("Planning failed: #{inspect(reason)}")
          end
        else
          Mix.shell().error("Function #{topology_atom}/0 not found in module #{module_name}")
        end

      {:error, _} ->
        Mix.shell().error("Module #{module_name} not found")
    end
  end

  defp start_services do
    # Start the State GenServer
    case CUL8er.Core.State.start_link([]) do
      {:ok, _} -> :ok
      {:error, {:already_started, _}} -> :ok
      error -> raise "Failed to start State service: #{inspect(error)}"
    end
  end

  defp display_plan(plan) do
    changes = plan.changes

    Mix.shell().info("\nPlanned changes:")
    Mix.shell().info("Hosts to create: #{Enum.join(changes.hosts.to_create, ", ")}")
    Mix.shell().info("Hosts to update: #{Enum.join(changes.hosts.to_update, ", ")}")
    Mix.shell().info("Hosts to delete: #{Enum.join(changes.hosts.to_delete, ", ")}")
    Mix.shell().info("Resources to create: #{Enum.join(changes.resources.to_create, ", ")}")
    Mix.shell().info("Resources to update: #{Enum.join(changes.resources.to_update, ", ")}")
    Mix.shell().info("Resources to delete: #{Enum.join(changes.resources.to_delete, ", ")}")
  end
end
