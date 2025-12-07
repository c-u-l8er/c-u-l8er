defmodule CUL8er.Core.Executor do
  @moduledoc """
  Deployment executor for C U L8er topologies.

  Orchestrates the deployment process by coordinating between hosts,
  resources, and deployment strategies. Provides plan/apply workflow
  similar to Terraform.
  """

  alias CUL8er.Core.{Incus, State}

  @type topology :: map()
  @type topology_name :: atom()
  @type deployment_opts :: keyword()
  @type result :: {:ok, term()} | {:error, term()}

  @doc """
  Deploys a topology to the infrastructure.

  ## Options
  - `:dry_run` - Plan changes but don't apply them
  - `:force` - Skip confirmation prompts
  - `:rollback_on_failure` - Automatically rollback on deployment failure
  """
  @spec deploy(topology_name(), topology(), deployment_opts()) :: result()
  def deploy(topology_name, topology, opts \\ []) do
    dry_run = Keyword.get(opts, :dry_run, false)

    with {:ok, plan} <- plan_changes(topology_name, topology),
         :ok <- if(dry_run, do: :ok, else: confirm_plan(plan, opts)),
         {:ok, _result} <- if(dry_run, do: {:ok, plan}, else: apply_plan(plan)) do
      # Save successful deployment state
      State.save(topology_name, %{topology: topology, deployed_at: DateTime.utc_now()})
      {:ok, :deployed}
    else
      {:error, reason} ->
        # Handle rollback if configured
        if Keyword.get(opts, :rollback_on_failure, true) do
          rollback(topology_name)
        end

        {:error, reason}
    end
  end

  @doc """
  Plans the changes needed to deploy a topology.

  Returns a plan showing what will be created, modified, or destroyed.
  """
  @spec plan_changes(topology_name(), topology()) :: {:ok, map()} | {:error, term()}
  def plan_changes(topology_name, topology) do
    # Validate topology structure
    with :ok <- validate_topology(topology) do
      # Get current state
      current_state =
        case State.load(topology_name) do
          {:ok, state} -> state
          {:error, :not_found} -> %{}
        end

      # Compare current vs desired state
      plan = %{
        topology_name: topology_name,
        current_state: current_state,
        desired_state: topology,
        changes: calculate_changes(current_state, topology),
        timestamp: DateTime.utc_now()
      }

      {:ok, plan}
    end
  end

  @doc """
  Applies a deployment plan.
  """
  @spec apply_plan(map()) :: result()
  def apply_plan(plan) do
    changes = plan.changes

    # Apply changes in order
    with :ok <- apply_host_changes(changes.hosts),
         :ok <- apply_resource_changes(changes.resources) do
      {:ok, :applied}
    end
  end

  @doc """
  Gets the current status of a deployed topology.
  """
  @spec status(topology_name()) :: {:ok, map()} | {:error, term()}
  def status(topology_name) do
    case State.load(topology_name) do
      {:ok, state} ->
        # Check actual state of resources
        actual_state = check_actual_state(state)
        {:ok, Map.put(state, :actual_state, actual_state)}

      error ->
        error
    end
  end

  @doc """
  Rolls back a topology to the previous state.
  """
  @spec rollback(topology_name()) :: result()
  def rollback(topology_name) do
    # Load previous state and restore
    # This is a simplified version - real rollback would use snapshots
    case State.load(topology_name) do
      {:ok, _state} ->
        # For now, just log the rollback
        # Real implementation would use snapshots
        CUL8er.Security.Audit.log(:deployment_rolled_back, %{topology: topology_name})
        {:ok, :rolled_back}

      error ->
        error
    end
  end

  @doc """
  Destroys a deployed topology.
  """
  @spec destroy(topology_name()) :: result()
  def destroy(topology_name) do
    # Load current state
    case State.load(topology_name) do
      {:ok, state} ->
        # Destroy all resources
        topology = state["topology"]

        Enum.each(topology["resources"] || %{}, fn {resource_name, resource} ->
          _host = topology["hosts"][resource["host"]]
          destroy_resource(String.to_atom(resource_name), %{current_state: topology})
        end)

        # Delete state
        State.delete(topology_name)

        CUL8er.Security.Audit.log(:topology_destroyed, %{topology: topology_name})
        {:ok, :destroyed}

      {:error, :not_found} ->
        {:error, :not_deployed}

      error ->
        error
    end
  end

  # Private functions

  defp calculate_changes(current_state, desired_state) do
    %{
      hosts: calculate_host_changes(current_state["hosts"] || %{}, desired_state.hosts || %{}),
      resources:
        calculate_resource_changes(
          current_state["resources"] || %{},
          desired_state.resources || %{}
        )
    }
  end

  defp calculate_host_changes(current_hosts, desired_hosts) do
    # Simple diff - in real implementation, this would be more sophisticated
    %{
      to_create: Map.keys(desired_hosts) -- Map.keys(current_hosts),
      to_update: Map.keys(desired_hosts) -- (Map.keys(desired_hosts) -- Map.keys(current_hosts)),
      to_delete: Map.keys(current_hosts) -- Map.keys(desired_hosts)
    }
  end

  defp calculate_resource_changes(current_resources, desired_resources) do
    # Simple diff for resources
    %{
      to_create: Map.keys(desired_resources) -- Map.keys(current_resources),
      to_update:
        Map.keys(desired_resources) --
          (Map.keys(desired_resources) -- Map.keys(current_resources)),
      to_delete: Map.keys(current_resources) -- Map.keys(desired_resources)
    }
  end

  defp confirm_plan(_plan, _opts) do
    # In a real implementation, this would prompt the user
    # For now, just return :ok
    :ok
  end

  defp apply_host_changes(_changes) do
    # For now, hosts are assumed to exist
    # In a real implementation, this might configure networking, etc.
    :ok
  end

  defp apply_resource_changes(changes) do
    # Apply resource changes
    Enum.each(changes.to_create, fn resource_name ->
      create_resource(resource_name, changes)
    end)

    Enum.each(changes.to_update, fn resource_name ->
      update_resource(resource_name, changes)
    end)

    Enum.each(changes.to_delete, fn resource_name ->
      delete_resource(resource_name, changes)
    end)

    :ok
  end

  defp create_resource(resource_name, changes) do
    # Get resource definition from desired state
    resource = changes.desired_state.resources[resource_name]
    host = changes.desired_state.hosts[resource.host]

    # Create the instance using Incus
    case Incus.create_instance(host, Atom.to_string(resource_name), resource.image) do
      {:ok, _output} ->
        CUL8er.Security.Audit.log(:resource_created, %{
          resource: resource_name,
          host: resource.host
        })

        :ok

      {:error, reason} ->
        {:error, {:create_failed, resource_name, reason}}
    end
  end

  defp update_resource(resource_name, _changes) do
    # For now, just log the update
    # Real implementation would handle configuration changes
    CUL8er.Security.Audit.log(:resource_updated, %{resource: resource_name})
    :ok
  end

  defp destroy_resource(resource_name, state) do
    # Get resource definition from state
    resource = state.current_state["resources"][Atom.to_string(resource_name)]
    host = state.current_state["hosts"][resource["host"]]

    # Delete the instance
    case Incus.delete_instance(host, Atom.to_string(resource_name)) do
      {:ok, _output} ->
        CUL8er.Security.Audit.log(:resource_destroyed, %{resource: resource_name})
        :ok

      {:error, reason} ->
        {:error, {:delete_failed, resource_name, reason}}
    end
  end

  defp delete_resource(resource_name, changes) do
    # Get current resource definition
    resource = changes.current_state["resources"][Atom.to_string(resource_name)]
    host = changes.current_state["hosts"][resource["host"]]

    # Delete the instance
    case Incus.delete_instance(host, Atom.to_string(resource_name)) do
      {:ok, _output} ->
        CUL8er.Security.Audit.log(:resource_destroyed, %{resource: resource_name})
        :ok

      {:error, reason} ->
        {:error, {:delete_failed, resource_name, reason}}
    end
  end

  defp check_actual_state(_state) do
    # Check actual state of deployed resources
    # This would query Incus to verify current state
    %{verified: false, message: "State checking not implemented yet"}
  end

  # Validate topology structure
  defp validate_topology(topology) do
    cond do
      not is_map(topology) ->
        {:error, :invalid_topology_structure}

      not Map.has_key?(topology, :name) ->
        {:error, :missing_topology_name}

      not Map.has_key?(topology, :hosts) ->
        {:error, :missing_hosts}

      not Map.has_key?(topology, :resources) ->
        {:error, :missing_resources}

      true ->
        :ok
    end
  end
end
