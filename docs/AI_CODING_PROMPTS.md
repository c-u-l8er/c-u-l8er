# C U L8er - AI Coding Prompts

Complete phase-by-phase implementation guide for AI coding assistants.

**Project:** C U L8er (Computer Units Load-8alancer)  
**URL:** https://c-u-l8er.link  
**Total Duration:** 11 weeks (226-280 hours)

---

# PHASE 1: Core DSL & Infrastructure Layer

**Duration:** Weeks 1-2 (40-50 hours)  
**Difficulty:** Medium  
**Goal:** Working DSL that parses topologies into data structures

## Objective

Create macro-based DSL that compiles this:

```elixir
use CUL8er

topology :production do
  host :remote do
    address "prod.example.com"
    platform :icusos
  end
  
  resource :web, type: :container, on: :remote do
    from_image "images:alpine/3.19"
    
    limits do
      cpu cores: 2
      memory gigabytes: 2
    end
  end
end
```

Into this structure:

```elixir
%{
  name: :production,
  hosts: %{remote: %{address: "prod.example.com", platform: :icusos}},
  resources: [%{name: :web, type: :container, image: "images:alpine/3.19", ...}]
}
```

## Implementation Checklist

- [ ] Create `mix.exs` with dependencies
- [ ] Create `lib/c_u_l8er/application.ex` (OTP app)
- [ ] Create `lib/c_u_l8er.ex` (main DSL entry, __using__ macro)
- [ ] Create `lib/c_u_l8er/dsl/infrastructure.ex` (host, resource macros)
- [ ] Create `lib/c_u_l8er/dsl/configuration.ex` (limits, network, environment macros)
- [ ] Create `lib/c_u_l8er/dsl/strategy.ex` (deployment strategy macros)
- [ ] Create `lib/c_u_l8er/dsl/cluster.ex` (cluster configuration macros)
- [ ] Write tests in `test/c_u_l8er/dsl_test.exs`
- [ ] Verify `mix compile` works
- [ ] Verify `mix test` passes

## Key Design Patterns

**Module Attributes for Accumulation:**
```elixir
Module.register_attribute(__MODULE__, :topologies, accumulate: true)
Module.register_attribute(__MODULE__, :current_topology, accumulate: false)
```

**Before Compile Hook:**
```elixir
@before_compile CUL8er

defmacro __before_compile__(env) do
  topologies = Module.get_attribute(env.module, :topologies)
  # Generate __topologies__/0 function
end
```

---

# PHASE 2: Incus Integration & State Management

**Duration:** Weeks 3-4 (50-60 hours)  
**Difficulty:** High  
**Goal:** Actually deploy containers and track state

## Objective

Make `MyTopology.deploy(:production)` create real Incus containers/VMs.

## Prerequisites

- Phase 1 complete
- Incus installed: `pacman -S incus`
- Test: `incus launch images:alpine/3.19 test && incus delete test --force`

## Implementation Checklist

- [ ] Create `lib/c_u_l8er/core/incus.ex`
  - [ ] `create_instance/4` - Launch containers/VMs
  - [ ] `list_instances/1` - List all instances
  - [ ] `info_instance/2` - Get instance details (JSON parsing)
  - [ ] `set_limits/3` - Set CPU/memory limits
  - [ ] `add_device/4` - Add network/storage devices
  - [ ] `exec/4` - Execute commands in instance
  - [ ] `snapshot/3` - Create snapshots
  - [ ] `restore_snapshot/3` - Restore from snapshot
  - [ ] `stop_instance/3` - Stop instance
  - [ ] `delete_instance/3` - Delete instance
  
- [ ] Create `lib/c_u_l8er/core/ssh.ex`
  - [ ] `exec/3` - Execute commands via SSH
  - [ ] Parse user@host format
  - [ ] Handle SSH keys
  
- [ ] Create `lib/c_u_l8er/core/state.ex` (GenServer)
  - [ ] `save/2` - Save deployment state to file/DB
  - [ ] `load/1` - Load deployment state
  - [ ] `list/0` - List all deployments
  - [ ] `diff/2` - Compare desired vs actual state
  - [ ] File backend (JSON in `.c_u_l8er/state/`)
  
- [ ] Create `lib/c_u_l8er/core/executor.ex`
  - [ ] `deploy/2` - Orchestrate deployment
  - [ ] `execute_plan/3` - Execute deployment plan
  - [ ] `create_resource/2` - Create single resource
  - [ ] `apply_configuration/2` - Apply limits/network/env
  
- [ ] Update `lib/c_u_l8er/application.ex`
  - [ ] Add `CUL8er.Core.State` to supervision tree
  
- [ ] Update `lib/c_u_l8er.ex`
  - [ ] Wire `deploy/2` to `Executor.deploy/2`
  - [ ] Wire `plan/1` to dry-run mode
  - [ ] Wire `status/1` to `State.load/1`
  
- [ ] Write integration tests
  - [ ] Test creating real containers (mark with @moduletag :integration)
  - [ ] Test state saving/loading
  - [ ] Test drift detection

## Key Implementation Points

**Execute Incus Commands:**
```elixir
defp execute(host, command) when host == "localhost" do
  case System.cmd("sh", ["-c", command], stderr_to_stdout: true) do
    {output, 0} -> {:ok, output}
    {error, code} -> {:error, {code, error}}
  end
end
```

**Parse JSON Responses:**
```elixir
def info_instance(host, name) do
  command = "incus info #{name} --format json"
  
  case execute(host, command) do
    {:ok, output} -> Jason.decode(output)
    error -> error
  end
end
```

**State as JSON File:**
```elixir
defp do_save(:file, state_dir, deployment_name, state_data) do
  path = Path.join(state_dir, "#{deployment_name}.json")
  json = Jason.encode!(state_data, pretty: true)
  File.write!(path, json)
end
```

---

# PHASE 2.5: Security Hardening

**Duration:** Week 4-5 (16-20 hours)  
**Difficulty:** Medium  
**Goal:** Add essential security layers for homelab deployments

## Objective

Implement 5 must-have security layers for homelab use:
1. Encrypted secrets management
2. Self-signed CA for HTTPS
3. Basic network zones
4. Container security (non-root, read-only)
5. Simple audit logging

## Prerequisites

- Phase 2 complete (Incus integration working)
- Basic Incus knowledge
- Understanding of TLS certificates

## Implementation Checklist

### Part 1: Secrets Management (6-8 hours)
- [ ] Create `CUL8er.Security.Secrets` GenServer
- [ ] Implement encrypted file backend
- [ ] Add Mix task `mix c_u_l8er.secret.set/get`
- [ ] Update DSL to support `secret` macro
- [ ] Test encryption/decryption

### Part 2: Certificate Management (5-6 hours)
- [ ] Create `CUL8er.Security.Certificates` module
- [ ] Implement self-signed CA generation
- [ ] Add certificate generation for domains
- [ ] Update DSL for certificates
- [ ] Test certificate creation and trust

### Part 3: Network Security (3-5 hours)
- [ ] Create `CUL8er.Security.Network` module
- [ ] Implement basic firewall zones
- [ ] Add network policies to DSL
- [ ] Test zone isolation

### Part 4: Container Security (2-4 hours)
- [ ] Create `CUL8er.Security.Container` module
- [ ] Implement non-root user profiles
- [ ] Add read-only root filesystem
- [ ] Update DSL security macros
- [ ] Test container hardening

### Part 5: Audit Logging (2-3 hours)
- [ ] Create `CUL8er.Security.Audit` GenServer
- [ ] Implement file-based logging
- [ ] Add audit events to executor
- [ ] Test logging functionality

## Key Implementation Points

### Secrets Management
```elixir
defmodule CUL8er.Security.Secrets do
  use GenServer

  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  def store(topology, key, value), do: GenServer.call(__MODULE__, {:store, topology, key, value})
  def retrieve(topology, key), do: GenServer.call(__MODULE__, {:retrieve, topology, key})

  def init(opts) do
    # Initialize encryption key from env
    key = System.get_env("MASTER_KEY") || raise "MASTER_KEY not set"
    {:ok, %{key: key, storage_path: opts[:storage_path] || "~/.c_u_l8er/secrets"}}
  end

  def handle_call({:store, topology, key, value}, _from, state) do
    encrypted = encrypt(value, state.key)
    path = Path.join([state.storage_path, to_string(topology), key <> ".enc"])
    File.mkdir_p!(Path.dirname(path))
    File.write!(path, encrypted)
    {:reply, :ok, state}
  end

  def handle_call({:retrieve, topology, key}, _from, state) do
    path = Path.join([state.storage_path, to_string(topology), key <> ".enc"])
    case File.read(path) do
      {:ok, encrypted} ->
        {:ok, decrypt(encrypted, state.key)}
      {:error, _} ->
        {:error, :not_found}
    end
    |> then(&{:reply, &1, state})
  end

  defp encrypt(plaintext, key) do
    # AES-256-CBC encryption
    :crypto.crypto_one_time(:aes_256_cbc, :base64.decode(key), <<0::128>>, plaintext, true)
  end

  defp decrypt(ciphertext, key) do
    # AES-256-CBC decryption
    :crypto.crypto_one_time(:aes_256_cbc, :base64.decode(key), <<0::128>>, ciphertext, false)
  end
end
```

### Mix Task for Secrets
```elixir
defmodule Mix.Tasks.CUL8er.Secret do
  use Mix.Task

  @shortdoc "Manage secrets"
  def run(["set", key]) do
    topology = Mix.Project.config()[:app]  # or from args
    value = IO.gets("Enter secret value: ") |> String.trim()
    :ok = CUL8er.Security.Secrets.store(topology, key, value)
    IO.puts("Secret stored")
  end

  def run(["get", key]) do
    topology = Mix.Project.config()[:app]
    case CUL8er.Security.Secrets.retrieve(topology, key) do
      {:ok, value} -> IO.puts(value)
      {:error, _} -> IO.puts("Secret not found")
    end
  end
end
```

### Certificate Management
```elixir
defmodule CUL8er.Security.Certificates.CA do
  def generate_ca(opts) do
    # Generate CA private key
    {:ok, ca_key} = :public_key.generate_key({:rsa, 2048, 65537})
    
    # Create CA certificate
    ca_cert = :public_key.pkix_sign(
      :public_key.pkix_encode(:Certificate, ca_template(opts), :otp),
      ca_key
    )
    
    # Save to files
    File.write!("ca.key", :public_key.pem_encode([{:PrivateKeyInfo, :public_key.pem_entry_encode(:PrivateKeyInfo, ca_key)}]))
    File.write!("ca.crt", :public_key.pem_encode([{:Certificate, ca_cert, :not_encrypted}]))
    
    {:ok, ca_cert, ca_key}
  end

  def generate_cert(domain, ca_key, ca_cert, opts) do
    # Generate cert private key
    {:ok, cert_key} = :public_key.generate_key({:rsa, 2048, 65537})
    
    # Create certificate
    cert = :public_key.pkix_sign(
      :public_key.pkix_encode(:Certificate, cert_template(domain, opts), :otp),
      ca_key
    )
    
    # Save to files
    File.write!("#{domain}.key", :public_key.pem_encode([{:PrivateKeyInfo, :public_key.pem_entry_encode(:PrivateKeyInfo, cert_key)}]))
    File.write!("#{domain}.crt", :public_key.pem_encode([{:Certificate, cert, :not_encrypted}]))
    
    {:ok, cert, cert_key}
  end

  defp ca_template(opts) do
    # CA certificate template
    %{
      version: :v3,
      serialNumber: 1,
      signature: {:sha256WithRSAEncryption, []},
      issuer: opts[:subject],
      validity: {:utcTime, {{2023,1,1},{0,0,0}}, {{2033,1,1},{0,0,0}}},
      subject: opts[:subject],
      subjectPublicKeyInfo: :public_key.generate_key({:rsa, 2048, 65537}),
      extensions: [
        {:basicConstraints, true, true},  # CA:TRUE
        {:keyUsage, [:digitalSignature, :keyCertSign, :crlSign], true}
      ]
    }
  end

  defp cert_template(domain, opts) do
    # Server certificate template
    %{
      version: :v3,
      serialNumber: 2,
      signature: {:sha256WithRSAEncryption, []},
      issuer: opts[:ca_subject],
      validity: {:utcTime, {{2023,1,1},{0,0,0}}, {{2024,1,1},{0,0,0}}},
      subject: {:rdnSequence, [[{:AttributeTypeAndValue, {2,5,4,3}, {:utf8String, domain}}]]},
      subjectPublicKeyInfo: :public_key.generate_key({:rsa, 2048, 65537}),
      extensions: [
        {:basicConstraints, false, false},
        {:keyUsage, [:digitalSignature, :keyEncipherment], true},
        {:extendedKeyUsage, [:serverAuth], true},
        {:subjectAltName, {:dNSName, domain}}
      ]
    }
  end
end
```

### Network Security
```elixir
defmodule CUL8er.Security.Network do
  def configure_zones(host, topology) do
    # Apply firewall rules for zones
    Enum.each(topology.zones, &create_zone_network(host, &1))
  end

  defp create_zone_network(host, zone) do
    # Create Incus network for zone
    network_name = "cul8er-#{zone.name}"
    
    # Incus commands to create network and attach rules
    commands = [
      "incus network create #{network_name} --type=bridge",
      "incus network set #{network_name} ipv4.firewall=true",
      "incus network set #{network_name} ipv6.firewall=true"
    ]
    
    Enum.each(commands, &System.cmd("ssh", [host.address, &1]))
  end

  defp apply_zone_rules(host, zone) do
    # Apply iptables rules for zone isolation
    rules = [
      "iptables -A FORWARD -i #{zone.interface} -s #{zone.allow_from} -j ACCEPT",
      "iptables -A FORWARD -i #{zone.interface} -j DROP"
    ]
    
    Enum.each(rules, &System.cmd("ssh", [host.address, &1]))
  end
end
```

### Container Security
```elixir
defmodule CUL8er.Security.Container do
  def apply_profile(host, container_name, profile) do
    # Apply security profile to container
    set_user(host, container_name, profile[:user][:uid], profile[:user][:gid])
    set_readonly_root(host, container_name)
    configure_capabilities(host, container_name, profile[:capabilities])
  end

  defp set_user(host, container, uid, gid) do
    # Set container to run as non-root
    System.cmd("ssh", [host.address, "incus config set #{container} raw.idmap 'uid #{uid} 0\ngid #{gid} 0'"])
    System.cmd("ssh", [host.address, "incus config set #{container} security.idmap.isolated true"])
  end

  defp set_readonly_root(host, container) do
    # Make root filesystem read-only
    System.cmd("ssh", [host.address, "incus config set #{container} security.privileged false"])
    System.cmd("ssh", [host.address, "incus config set #{container} security.readonly.rootfs true"])
  end

  defp configure_capabilities(host, container, caps) do
    # Drop all capabilities except specified
    System.cmd("ssh", [host.address, "incus config set #{container} security.syscalls.deny_default true"])
    
    Enum.each(caps, fn cap ->
      System.cmd("ssh", [host.address, "incus config set #{container} security.syscalls.allow #{cap}"])
    end)
  end
end
```

### Audit Logging
```elixir
defmodule CUL8er.Security.Audit do
  use GenServer

  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  def log(event, metadata \\ %{}), do: GenServer.cast(__MODULE__, {:log, event, metadata})

  def init(opts) do
    log_path = opts[:log_path] || "~/.c_u_l8er/logs/audit.log"
    File.mkdir_p!(Path.dirname(log_path))
    {:ok, %{log_path: log_path}}
  end

  def handle_cast({:log, event, metadata}, state) do
    timestamp = DateTime.utc_now() |> DateTime.to_iso8601()
    hostname = get_hostname()
    log_entry = "#{timestamp} #{hostname} #{event} #{Jason.encode!(metadata)}\n"
    
    File.write!(state.log_path, log_entry, [:append])
    {:noreply, state}
  end

  defp get_hostname do
    case :inet.gethostname() do
      {:ok, hostname} -> to_string(hostname)
      _ -> "unknown"
    end
  end
end
```

### Integration with Executor
```elixir
defmodule CUL8er.Core.Executor do
  def deploy(topology, opts) do
    CUL8er.Security.Audit.log(:deployment_started, %{topology: topology.name})
    
    # ... existing deployment logic ...
    
    case result do
      {:ok, _} ->
        CUL8er.Security.Audit.log(:deployment_completed, %{topology: topology.name})
      {:error, reason} ->
        CUL8er.Security.Audit.log(:deployment_failed, %{topology: topology.name, reason: reason})
    end
  end
end
```

## Testing Strategy

### Unit Tests
```elixir
defmodule CUL8er.Security.SecretsTest do
  use ExUnit.Case, async: true

  setup do
    # Set up test encryption key
    key = :base64.encode(:crypto.strong_rand_bytes(32))
    System.put_env("MASTER_KEY", key)
    
    # Start secrets server
    {:ok, _} = CUL8er.Security.Secrets.start_link(storage_path: "/tmp/test_secrets")
    
    on_exit(fn ->
      System.delete_env("MASTER_KEY")
      File.rm_rf("/tmp/test_secrets")
    end)
    
    :ok
  end

  test "stores and retrieves secrets" do
    assert :ok = CUL8er.Security.Secrets.store(:test, "db_pass", "secret123")
    assert {:ok, "secret123"} = CUL8er.Security.Secrets.retrieve(:test, "db_pass")
  end

  test "secrets are encrypted on disk" do
    CUL8er.Security.Secrets.store(:test, "key", "value")
    
    # Check file exists and is not plaintext
    path = "/tmp/test_secrets/test/key.enc"
    assert File.exists?(path)
    content = File.read!(path)
    refute content == "value"
  end
end
```

### Integration Tests
```elixir
defmodule CUL8er.Integration.SecurityTest do
  use ExUnit.Case

  test "deploys with encrypted secrets" do
    defmodule TestTopology do
      use CUL8er
      
      topology :test do
        secrets do
          backend :encrypted_file
          storage_path "/tmp/test_secrets"
        end
        
        host :local do
          address "localhost"
          platform :arch_linux
        end
        
        resource :test, type: :container, on: :local do
          environment do
            secret :TEST_VAR, from: :secret_store, key: "test_var"
          end
        end
      end
    end

    # Store secret
    :ok = CUL8er.Security.Secrets.store(:test, "test_var", "secret_value")
    
    # Deploy
    {:ok, _} = TestTopology.deploy(:test)
    
    # Verify secret in container
    {:ok, env} = Incus.exec("test_test", "env")
    assert env =~ "TEST_VAR=secret_value"
  end

  test "containers run as non-root" do
    defmodule TestTopology do
      use CUL8er
      
      topology :test do
        security do
          defaults do
            user uid: 1000, gid: 1000
          end
        end
        
        host :local do
          address "localhost"
          platform :arch_linux
        end
        
        resource :test, type: :container, on: :local do
        end
      end
    end

    {:ok, _} = TestTopology.deploy(:test)
    
    # Check container runs as uid 1000
    {:ok, uid} = Incus.exec("test_test", "id -u")
    assert uid == "1000"
  end
end
```

## Deliverables

- [ ] `lib/c_u_l8er/security/` modules implemented
- [ ] Mix tasks for secrets and certificates
- [ ] DSL extensions for security
- [ ] Unit and integration tests passing
- [ ] Documentation updated

## Success Criteria

- [ ] Can store/retrieve encrypted secrets
- [ ] Self-signed CA generates trusted certificates
- [ ] Network zones isolate containers
- [ ] Containers run as non-root with read-only root
- [ ] Audit log captures deployment events
- [ ] All security tests pass

## Next Steps

After Phase 2.5, proceed to Phase 3 with secure foundation in place.

# PHASE 3: Deployment Strategies

**Duration:** Weeks 5-6 (40-50 hours)  
**Difficulty:** High  
**Goal:** Rolling, blue-green, canary deployments with health checks

## Objective

Implement production-grade deployment strategies with zero downtime.

## Implementation Checklist

- [ ] Create `lib/c_u_l8er/strategies/rolling.ex`
  - [ ] `execute/2` - Rolling deployment
  - [ ] `process_batch/3` - Deploy batch of resources
  - [ ] `chunk_resources/2` - Group into batches
  - [ ] Snapshot before updates
  - [ ] Rollback batch on failure
  
- [ ] Create `lib/c_u_l8er/strategies/blue_green.ex`
  - [ ] `execute/2` - Blue-green deployment
  - [ ] `create_environment/3` - Create parallel env (_blue/_green suffix)
  - [ ] `verify_environment/3` - Health check new env
  - [ ] `switch_traffic/3` - Switch load balancer
  - [ ] `cleanup_environment/2` - Remove old env
  
- [ ] Create `lib/c_u_l8er/strategies/canary.ex`
  - [ ] `execute/2` - Canary deployment
  - [ ] `deploy_canary/1` - Deploy canary instances (_canary suffix)
  - [ ] `execute_steps/4` - Gradually increase traffic
  - [ ] `update_traffic_split/2` - Update LB weights
  - [ ] `rollback_canary/1` - Remove canary on failure
  
- [ ] Create `lib/c_u_l8er/observable/health.ex`
  - [ ] `check/3` - Perform health check
  - [ ] HTTP endpoint checking (curl inside container)
  - [ ] Retry logic with backoff
  - [ ] Configurable timeout and expected status
  
- [ ] Update `lib/c_u_l8er/core/executor.ex`
  - [ ] Add strategy selection logic
  - [ ] Route to appropriate strategy module
  
- [ ] Write strategy tests

## Key Features

**Rolling Deployment:**
- Update N resources at a time
- Health check each batch before continuing
- Automatic rollback on failure

**Blue-Green:**
- Create complete parallel environment
- Switch all traffic at once
- Keep old environment for instant rollback

**Canary:**
- Deploy canary instances alongside prod
- Gradually increase traffic (10% → 25% → 50% → 100%)
- Monitor metrics at each step
- Automatic rollback if metrics degrade

---

# PHASE 4: Clustering & Observability

**Duration:** Weeks 7-8 (40-50 hours)  
**Difficulty:** Medium-High  
**Goal:** Automatic Elixir clustering and built-in metrics

## Objective

Automatically form Elixir clusters and expose telemetry metrics.

## Implementation Checklist

- [ ] Create `lib/c_u_l8er/cluster/manager.ex` (GenServer)
  - [ ] `connect_nodes/1` - Connect Elixir nodes
  - [ ] `setup_cluster/2` - Configure libcluster
  - [ ] Cookie management
  - [ ] Node discovery strategies
  
- [ ] Create `lib/c_u_l8er/cluster/topology.ex`
  - [ ] Build libcluster topology from DSL
  - [ ] Support Epmd, Gossip, Kubernetes strategies
  
- [ ] Create `lib/c_u_l8er/observable/metrics.ex`
  - [ ] Define Telemetry events
  - [ ] Track deployment duration
  - [ ] Track resource counts
  - [ ] Track health check results
  
- [ ] Update `lib/c_u_l8er/core/executor.ex`
  - [ ] Emit telemetry events
  - [ ] Deploy Elixir releases
  - [ ] Setup clustering after deployment
  
- [ ] Add libcluster to supervision tree
- [ ] Write clustering tests (multi-node)

## Key Implementation

**libcluster Integration:**
```elixir
defp build_topology(cluster_config) do
  [
    {cluster_config.name, [
      strategy: cluster_config.strategy,
      config: [
        nodes: cluster_config.nodes,
        cookie: get_cookie(cluster_config.cookie)
      ]
    ]}
  ]
end
```

**Telemetry Events:**
```elixir
:telemetry.execute(
  [:c_u_l8er, :deployment, :complete],
  %{duration: duration},
  %{topology: topology.name, resources: length(resources)}
)
```

---

# PHASE 5: Testing, CLI & Polish

**Duration:** Weeks 9-10 (40-50 hours)  
**Difficulty:** Medium  
**Goal:** Production-ready with comprehensive tests and CLI

## Implementation Checklist

- [ ] Create Mix tasks
  - [ ] `lib/mix/tasks/c_u_l8er.deploy.ex` - Deploy topology
  - [ ] `lib/mix/tasks/c_u_l8er.plan.ex` - Show changes
  - [ ] `lib/mix/tasks/c_u_l8er.status.ex` - Show current state
  - [ ] `lib/mix/tasks/c_u_l8er.rollback.ex` - Rollback deployment
  - [ ] `lib/mix/tasks/c_u_l8er.destroy.ex` - Destroy topology
  
- [ ] Comprehensive testing
  - [ ] Unit tests for all modules (80%+ coverage)
  - [ ] Integration tests with real Incus
  - [ ] Multi-node clustering tests
  - [ ] Strategy tests (rolling/blue-green/canary)
  - [ ] Mocks for Incus CLI responses
  
- [ ] Error handling
  - [ ] Wrap all Incus calls in try/rescue
  - [ ] Detailed error messages
  - [ ] Proper error types
  - [ ] Logging throughout
  
- [ ] Documentation
  - [ ] Add @moduledoc to all modules
  - [ ] Add @doc to all public functions
  - [ ] Add @typespecs everywhere
  - [ ] Generate HexDocs
  - [ ] Write comprehensive README
  - [ ] Write DEPLOYMENT_GUIDE
  
- [ ] Examples
  - [ ] Simple Phoenix app deployment
  - [ ] Multi-node cluster
  - [ ] Blue-green deployment
  - [ ] Remote (icusos) deployment
  
- [ ] CI/CD
  - [ ] GitHub Actions workflow
  - [ ] Run tests on PR
  - [ ] Check code formatting
  - [ ] Run Credo
  - [ ] Run Dialyzer

## Mix Task Example

```elixir
defmodule Mix.Tasks.CUL8er.Deploy do
  use Mix.Task
  
  @shortdoc "Deploy a topology"
  
  def run(args) do
    Mix.Task.run("app.start")
    
    {opts, [topology_name | _], _} = OptionParser.parse(args,
      switches: [dry_run: :boolean, force: :boolean]
    )
    
    topology_module = String.to_atom("Elixir.#{Macro.camelize(topology_name)}")
    
    topology_atom = String.to_atom(topology_name)
    
    case apply(topology_module, :deploy, [topology_atom, opts]) do
      {:ok, _} -> Mix.shell().info("Deployment successful")
      {:error, reason} -> Mix.shell().error("Deployment failed: #{inspect(reason)}")
    end
  end
end
```

---

# COMPREHENSIVE TESTING STRATEGY

## Unit Tests

```elixir
# test/c_u_l8er/dsl_test.exs
test "parses topology with all layers" do
  assert [topology] = TestTopology.__topologies__()
  assert topology.name == :test
  assert length(topology.resources) == 2
  assert topology.strategy.approach == :rolling
end

# test/c_u_l8er/core/state_test.exs
test "saves and loads state" do
  state = %{deployment_name: :test, resources: []}
  assert :ok = State.save(:test, state)
  assert {:ok, loaded} = State.load(:test)
  assert loaded.deployment_name == :test
end
```

## Integration Tests

```elixir
# test/integration/deployment_test.exs
@moduletag :integration

test "deploys container to local Incus" do
  assert {:ok, _} = TestTopology.deploy(:test)
  
  # Verify container exists
  assert {:ok, instances} = Incus.list_instances("localhost")
  assert Enum.any?(instances, &(&1.name == "web"))
  
  # Cleanup
  Incus.delete_instance("localhost", "web", force: true)
end
```

---

# FINAL DELIVERABLES

## Code Structure
```
c_u_l8er/
├── lib/
│   ├── c_u_l8er.ex                           # Main DSL
│   ├── c_u_l8er/
│   │   ├── application.ex                   # OTP app
│   │   ├── dsl/
│   │   │   ├── infrastructure.ex            # host, resource
│   │   │   ├── configuration.ex             # limits, network
│   │   │   ├── strategy.ex                  # deployment strategy
│   │   │   └── cluster.ex                   # clustering
│   │   ├── core/
│   │   │   ├── incus.ex                     # Incus CLI client
│   │   │   ├── ssh.ex                       # SSH client
│   │   │   ├── state.ex                     # State management
│   │   │   └── executor.ex                  # Deployment orchestration
│   │   ├── strategies/
│   │   │   ├── rolling.ex                   # Rolling deployments
│   │   │   ├── blue_green.ex                # Blue-green deployments
│   │   │   └── canary.ex                    # Canary deployments
│   │   ├── cluster/
│   │   │   ├── manager.ex                   # Cluster management
│   │   │   └── topology.ex                  # libcluster integration
│   │   └── observable/
│   │       ├── metrics.ex                   # Telemetry
│   │       └── health.ex                    # Health checking
│   └── mix/
│       └── tasks/
│           ├── c_u_l8er.deploy.ex
│           ├── c_u_l8er.plan.ex
│           ├── c_u_l8er.status.ex
│           ├── c_u_l8er.rollback.ex
│           └── c_u_l8er.destroy.ex
├── test/
│   ├── c_u_l8er/
│   │   ├── dsl_test.exs
│   │   ├── core/
│   │   └── strategies/
│   └── integration/
└── examples/
    ├── phoenix_app.ex
    ├── multi_node_cluster.ex
    └── blue_green_deploy.ex
```

## Success Criteria

- [ ] All tests pass (`mix test`)
- [ ] Integration tests pass (`mix test --only integration`)
- [ ] Code formatted (`mix format --check-formatted`)
- [ ] No warnings (`mix compile --warnings-as-errors`)
- [ ] Credo passes (`mix credo --strict`)
- [ ] Dialyzer passes (`mix dialyzer`)
- [ ] Documentation complete (`mix docs`)
- [ ] Can deploy Phoenix app in <30 seconds
- [ ] Can form 3-node cluster automatically
- [ ] Zero-downtime rolling updates work
- [ ] Automatic rollback on failure works

---

# USAGE EXAMPLES

## Basic Deployment

```elixir
defmodule MyApp.Infrastructure do
  use CUL8er
  
  topology :production do
    host :web_server do
      address "deploy@prod.example.com"
      platform :icusos
      credentials ssh: [key: "~/.ssh/deploy_key"]
    end
    
    resource :web, type: :container, on: :web_server do
      from_image "images:alpine/3.19"
      
      limits do
        cpu cores: 4
        memory gigabytes: 8
      end
      
      network do
        expose port: 4000, as: 443, protocol: :https
      end
      
      environment do
        set :MIX_ENV, "prod"
        secret :SECRET_KEY_BASE, from: :system
      end
      
      deploy release: :my_app, version: "1.0.0"
    end
    
    strategy do
      approach :rolling
      max_parallel 1
      
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
  end
end

# Deploy
mix c_u_l8er.deploy production

# Or programmatically
MyApp.Infrastructure.deploy(:production)
```

## Multi-Node Cluster

```elixir
topology :cluster do
  host :local do
    address "localhost"
    platform :arch_linux
  end
  
  resource :node_1, type: :container, on: :local do
    from_image "images:alpine/3.19"
    deploy release: :my_app
  end
  
  resource :node_2, type: :container, on: :local do
    from_image "images:alpine/3.19"
    deploy release: :my_app
  end
  
  resource :node_3, type: :container, on: :local do
    from_image "images:alpine/3.19"
    deploy release: :my_app
  end
  
  cluster :app_cluster do
    nodes [:node_1, :node_2, :node_3]
    discovery strategy: Cluster.Strategy.Epmd
    cookie from: :system, key: "RELEASE_COOKIE"
  end
end
```

---

# TIMELINE SUMMARY

**Week 1-2:** DSL Foundation (40-50h)
**Week 3-4:** Incus Integration (50-60h)
**Week 5-6:** Deployment Strategies (40-50h)
**Week 7-8:** Clustering & Observability (40-50h)
**Week 9-10:** Testing & Polish (40-50h)

**Total:** 10 weeks, 250-300 hours

---

# TIPS FOR AI IMPLEMENTATION

1. **Start Simple:** Get basic functionality working before adding complexity
2. **Test Continuously:** Write tests alongside code, run frequently
3. **Use Typespecs:** Add @spec to all functions for better tooling
4. **Error Handling:** Wrap all external calls (Incus, SSH) in proper error handling
5. **Logging:** Add Logger calls for debugging and operations
6. **Documentation:** Write @doc as you code, not after
7. **Examples:** Create working examples to verify each phase
8. **Incremental:** Complete each phase fully before moving to next
