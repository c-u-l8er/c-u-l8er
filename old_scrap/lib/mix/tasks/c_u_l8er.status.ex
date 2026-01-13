defmodule Mix.Tasks.CUL8er.Status do
  @moduledoc """
  Shows the status of a deployed C U L8er topology.

  Usage:
      mix c_u_l8er.status <topology>

  Examples:
      mix c_u_l8er.status production
  """

  use Mix.Task

  @shortdoc "Show status of a C U L8er topology"

  def run(args) do
    case args do
      [topology_name] ->
        show_status(topology_name)

      _ ->
        Mix.shell().error("Usage: mix c_u_l8er.status <topology>")
        exit({:shutdown, 1})
    end
  end

  defp show_status(topology_name) do
    # Start required services
    start_services()

    topology_atom = String.to_atom(topology_name)

    Mix.shell().info("Checking status of topology #{topology_name}...")

    case CUL8er.Core.Executor.status(topology_atom) do
      {:ok, status} ->
        display_status(status)

      {:error, reason} ->
        Mix.shell().error("Status check failed: #{inspect(reason)}")
        exit({:shutdown, 1})
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

  defp display_status(status) do
    Mix.shell().info("\nTopology Status:")
    Mix.shell().info("Name: #{status.topology.name}")
    Mix.shell().info("Deployed at: #{status.deployed_at}")

    if status.actual_state do
      Mix.shell().info("Actual state: #{inspect(status.actual_state)}")
    else
      Mix.shell().info("No actual state information available")
    end

    Mix.shell().info("\nHosts:")

    Enum.each(status.topology.hosts, fn {name, host} ->
      Mix.shell().info("  #{name}: #{host.address} (#{host.platform})")
    end)

    Mix.shell().info("\nResources:")

    Enum.each(status.topology.resources, fn {name, resource} ->
      Mix.shell().info("  #{name}: #{resource.type} on #{resource.host}")
    end)
  end
end
