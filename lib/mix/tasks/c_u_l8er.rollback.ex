defmodule Mix.Tasks.CUL8er.Rollback do
  @moduledoc """
  Rolls back a C U L8er topology to the previous state.

  Usage:
      mix c_u_l8er.rollback <topology>

  Examples:
      mix c_u_l8er.rollback production
  """

  use Mix.Task

  @shortdoc "Rollback a C U L8er topology"

  def run(args) do
    case args do
      [topology_name] ->
        rollback_topology(topology_name)

      _ ->
        Mix.shell().error("Usage: mix c_u_l8er.rollback <topology>")
        exit({:shutdown, 1})
    end
  end

  defp rollback_topology(topology_name) do
    topology_atom = String.to_atom(topology_name)

    Mix.shell().info("Rolling back topology #{topology_name}...")

    case CUL8er.Core.Executor.rollback(topology_atom) do
      {:ok, :rolled_back} ->
        Mix.shell().info("Rollback successful!")

      {:error, reason} ->
        Mix.shell().error("Rollback failed: #{inspect(reason)}")
        exit({:shutdown, 1})
    end
  end
end
