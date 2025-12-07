defmodule Mix.Tasks.CUL8er.Destroy do
  @moduledoc """
  Destroys a C U L8er topology.

  Usage:
      mix c_u_l8er.destroy <topology>

  Examples:
      mix c_u_l8er.destroy production
  """

  use Mix.Task

  @shortdoc "Destroy a C U L8er topology"

  def run(args) do
    case args do
      [topology_name] ->
        destroy_topology(topology_name)

      _ ->
        Mix.shell().error("Usage: mix c_u_l8er.destroy <topology>")
        exit({:shutdown, 1})
    end
  end

  defp destroy_topology(topology_name) do
    topology_atom = String.to_atom(topology_name)

    Mix.shell().info("Destroying topology #{topology_name}...")

    case CUL8er.Core.Executor.destroy(topology_atom) do
      {:ok, :destroyed} ->
        Mix.shell().info("Destruction successful!")

      {:error, reason} ->
        Mix.shell().error("Destruction failed: #{inspect(reason)}")
        exit({:shutdown, 1})
    end
  end
end
