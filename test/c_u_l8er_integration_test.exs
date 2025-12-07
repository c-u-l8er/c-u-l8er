defmodule CUL8erIntegrationTest do
  use ExUnit.Case
  doctest CUL8er

  @moduletag :integration

  setup do
    # Create a temporary directory for test state
    test_dir = Path.join(System.tmp_dir!(), "c_u_l8er_test_#{:rand.uniform(1000)}")
    File.mkdir_p!(test_dir)

    # Set up test environment
    original_state_dir = System.get_env("CUL8ER_STATE_DIR")
    System.put_env("CUL8ER_STATE_DIR", test_dir)

    on_exit(fn ->
      # Clean up
      File.rm_rf!(test_dir)

      if original_state_dir do
        System.put_env("CUL8ER_STATE_DIR", original_state_dir)
      else
        System.delete_env("CUL8ER_STATE_DIR")
      end
    end)

    %{test_dir: test_dir}
  end

  test "full deployment workflow with Mix tasks", %{test_dir: _test_dir} do
    # Test the complete workflow: plan -> deploy -> status -> destroy

    # First verify the module is available
    assert Code.ensure_loaded(Examples.SimpleTopology) == {:module, Examples.SimpleTopology}
    assert function_exported?(Examples.SimpleTopology, :simple, 0)

    # 1. Test planning
    {output, exit_code} =
      System.cmd("mix", ["c_u_l8er.plan", "Examples.SimpleTopology", "simple"],
        stderr_to_stdout: true
      )

    assert exit_code == 0
    assert String.contains?(output, "Planning changes")
    assert String.contains?(output, "Resources to create: web")

    # 2. Test deployment (dry run first)
    {output, exit_code} =
      System.cmd("mix", ["c_u_l8er.deploy", "Examples.SimpleTopology", "simple", "--dry-run"],
        stderr_to_stdout: true
      )

    assert exit_code == 0
    assert String.contains?(output, "DRY RUN")
    assert String.contains?(output, "Planning deployment")

    # 3. Test status (should show not deployed initially)
    {output, exit_code} = System.cmd("mix", ["c_u_l8er.status", "simple"], stderr_to_stdout: true)
    # Should fail because not deployed
    assert exit_code == 1
    assert String.contains?(output, "Status check failed")

    # Note: Real deployment would require Incus to be running
    # For now, we test the command structure and error handling
  end

  test "topology DSL creates correct data structures" do
    # Test that the DSL produces the expected data structures
    assert Code.ensure_loaded(Examples.SimpleTopology) == {:module, Examples.SimpleTopology}
    assert function_exported?(Examples.SimpleTopology, :simple, 0)

    topology = Examples.SimpleTopology.simple()

    assert topology.name == :simple
    assert Map.has_key?(topology.hosts, :local)
    assert Map.has_key?(topology.resources, :web)

    host = topology.hosts.local
    assert host.address == "localhost"
    assert host.platform == :arch_linux

    resource = topology.resources.web
    assert resource.type == :container
    assert resource.host == :local
    assert resource.image == "images:alpine/3.19"
    assert Map.has_key?(resource.config, :limits)
    assert Map.has_key?(resource.config, :network)
    assert Map.has_key?(resource.config, :environment)
  end

  test "state management works correctly" do
    # Test state saving and loading
    test_topology = :test_topology
    test_data = %{name: :test, hosts: %{}, resources: %{}, deployed_at: DateTime.utc_now()}

    # Save state
    assert :ok = CUL8er.Core.State.save(test_topology, test_data)

    # Load state
    assert {:ok, loaded_data} = CUL8er.Core.State.load(test_topology)
    assert loaded_data["name"] == "test"

    # List topologies
    topologies = CUL8er.Core.State.list_topologies()
    assert test_topology in topologies

    # Delete state
    assert :ok = CUL8er.Core.State.delete(test_topology)
    assert {:error, :not_found} = CUL8er.Core.State.load(test_topology)
  end

  test "secrets management basic functionality" do
    # Set up test environment
    original_key = System.get_env("MASTER_KEY")
    test_key = "test_master_key_12345"
    System.put_env("MASTER_KEY", test_key)

    on_exit(fn ->
      if original_key do
        System.put_env("MASTER_KEY", original_key)
      else
        System.delete_env("MASTER_KEY")
      end
    end)

    test_topology = :test_secrets
    test_key_name = "test_key"
    test_value = "secret"

    # Store secret
    assert :ok = CUL8er.Security.Secrets.store(test_topology, test_key_name, test_value)

    # Retrieve secret
    assert {:ok, ^test_value} = CUL8er.Security.Secrets.retrieve(test_topology, test_key_name)

    # List keys
    keys = CUL8er.Security.Secrets.list_keys(test_topology)
    assert test_key_name in keys
  end

  test "audit logging captures events" do
    # Test that audit logging works
    test_event = :test_event
    test_metadata = %{user: "test_user", action: "test_action"}

    # Log event
    assert :ok = CUL8er.Security.Audit.log(test_event, test_metadata)

    # Note: In a real test, we'd check the log file contents
    # But for now, we just verify the function doesn't crash
  end
end
