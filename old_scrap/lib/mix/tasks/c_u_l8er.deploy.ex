defmodule Mix.Tasks.CUL8er.Deploy do
  @moduledoc """
  Deploys a C U L8er topology.

  Usage:
      mix c_u_l8er.deploy <module> <topology> [options]

  Options:
      --dry-run    Show what would be deployed without actually deploying
      --force      Skip confirmation prompts

  Examples:
      mix c_u_l8er.deploy MyApp.Topology production
      mix c_u_l8er.deploy MyApp.Topology staging --dry-run
  """

  use Mix.Task

  @shortdoc "Deploy a C U L8er topology"

  def run(args) do
    {opts, parsed_args, _} =
      OptionParser.parse(args, switches: [dry_run: :boolean, force: :boolean])

    case parsed_args do
      [module_name, topology_name] ->
        deploy_topology(module_name, topology_name, opts)

      _ ->
        Mix.shell().error("Usage: mix c_u_l8er.deploy <module> <topology> [options]")
        exit({:shutdown, 1})
    end
  end

  defp deploy_topology(module_name, topology_name, opts) do
    # Start required services
    start_services()

    module = String.to_atom("Elixir.#{module_name}")
    topology_atom = String.to_atom(topology_name)

    case Code.ensure_loaded(module) do
      {:module, _} ->
        if function_exported?(module, topology_atom, 0) do
          # Get the topology data
          topology_data = apply(module, topology_atom, [])

          # Deploy
          Mix.shell().info("Deploying topology #{topology_name} from #{module_name}...")

          if Keyword.get(opts, :dry_run, false) do
            Mix.shell().info("DRY RUN - Planning deployment...")

            case CUL8er.Core.Executor.plan_changes(topology_atom, topology_data) do
              {:ok, plan} ->
                display_plan(plan)
                Mix.shell().info("Use --force to apply this plan")

              {:error, reason} ->
                Mix.shell().error("Planning failed: #{inspect(reason)}")
            end
          else
            case CUL8er.Core.Executor.deploy(topology_atom, topology_data, opts) do
              {:ok, :deployed} ->
                Mix.shell().info("Deployment successful!")

              {:error, reason} ->
                Mix.shell().error("Deployment failed: #{inspect(reason)}")
                exit({:shutdown, 1})
            end
          end
        else
          Mix.shell().error("Function #{topology_atom}/0 not found in module #{module_name}")
        end

      {:error, _} ->
        Mix.shell().error("Module #{module_name} not found")
    end
  end

  defp start_services do
    # Start required GenServers
    start_service(CUL8er.Core.State, "State")
    start_service(CUL8er.Security.Secrets, "Secrets")
    start_service(CUL8er.Security.Audit, "Audit")
  end

  defp start_service(module, name) do
    case module.start_link([]) do
      {:ok, _} -> :ok
      {:error, {:already_started, _}} -> :ok
      error -> raise "Failed to start #{name} service: #{inspect(error)}"
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
