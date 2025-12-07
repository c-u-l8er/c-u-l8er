# PHASE 2.5: Security Hardening (Homelab Edition)

**Duration:** Week 4-5 (16-20 hours)  
**Difficulty:** Medium  
**Goal:** Production-ready security for homelab deployment  
**Prerequisites:** Phase 2 complete (Incus Integration & State)

---

## Overview

This phase adds essential security features between core functionality (Phase 2) and deployment strategies (Phase 3). We implement the **5 must-have security layers** for homelab use:

1. Encrypted secrets management
2. Self-signed certificate authority
3. Basic network isolation
4. Container security defaults
5. Simple audit logging

**Why Phase 2.5?**
- Security should be built-in, not bolted-on
- Easier to implement early than retrofit later
- Sets good habits for all future development
- Enables HTTPS and secret management for Phase 3+

---

## Security Architecture for Homelab

```
┌─────────────────────────────────────────────────────┐
│                   Your Laptop                       │
│  ┌──────────────────────────────────────────────┐  │
│  │  C U L8er CLI                                 │  │
│  │  - Encrypted secrets (~/.c_u_l8er/secrets/)   │  │
│  │  - CA certificates (~/.c_u_l8er/ca/)          │  │
│  │  - Audit logs      (~/.c_u_l8er/logs/)        │  │
│  └──────────────────────────────────────────────┘  │
└──────────────────┬──────────────────────────────────┘
                   │ SSH (your user)
                   │
      ┌────────────┼────────────┬────────────────┐
      │            │            │                │
  ┌───▼───┐    ┌───▼───┐    ┌───▼───┐      ┌────▼────┐
  │ Node1 │    │ Node2 │    │ Node3 │      │  DMZ    │
  │  DB   │    │  Web  │    │ Cache │      │  (opt)  │
  └───────┘    └───────┘    └───────┘      └─────────┘
      │            │            │
      └────────────┴────────────┘
         Internal Network
         (containers only)
```

---

## Implementation Checklist

### Part 1: Secrets Management (6-8 hours)

- [ ] Create `lib/c_u_l8er/security/secrets.ex`
  - [ ] `SecretStore` GenServer
  - [ ] `encrypt/2` - Encrypt secret with master key
  - [ ] `decrypt/2` - Decrypt secret
  - [ ] `store/3` - Store encrypted secret to file
  - [ ] `retrieve/2` - Retrieve and decrypt secret
  - [ ] `list/1` - List all secret keys (not values!)
  - [ ] `rotate_key/1` - Re-encrypt all secrets with new key

- [ ] Create `lib/c_u_l8er/security/secrets/backend.ex`
  - [ ] Behaviour for secret backends
  - [ ] `EncryptedFile` implementation
  - [ ] Optional: `PasswordStore` implementation (uses `pass`)

- [ ] Update `lib/c_u_l8er/dsl/configuration.ex`
  - [ ] Add `secret/3` macro to environment block
  - [ ] Support `from: :secret_store` option

- [ ] Create Mix task `lib/mix/tasks/c_u_l8er.secret.ex`
  - [ ] `mix c_u_l8er.secret.set KEY` - Store secret
  - [ ] `mix c_u_l8er.secret.get KEY` - Retrieve secret (masked)
  - [ ] `mix c_u_l8er.secret.list` - List all keys
  - [ ] `mix c_u_l8er.secret.delete KEY` - Remove secret

- [ ] Write tests `test/c_u_l8er/security/secrets_test.exs`

### Part 2: Certificate Management (5-6 hours)

- [ ] Create `lib/c_u_l8er/security/certificates.ex`
  - [ ] `CA` module - Manage certificate authority
  - [ ] `generate_ca/1` - Create self-signed CA
  - [ ] `generate_cert/3` - Issue certificate from CA
  - [ ] `renew_cert/2` - Renew certificate
  - [ ] `revoke_cert/2` - Revoke certificate
  - [ ] `verify_cert/2` - Verify certificate validity

- [ ] Create `lib/c_u_l8er/security/certificates/storage.ex`
  - [ ] Store CA in `~/.c_u_l8er/ca/`
  - [ ] Store issued certs in `~/.c_u_l8er/certs/`
  - [ ] Export to PEM format
  - [ ] Import CA to Incus

- [ ] Update `lib/c_u_l8er/dsl/configuration.ex`
  - [ ] Add `certificate` option to `expose` block
  - [ ] Generate cert if doesn't exist
  - [ ] Configure Incus proxy device with cert

- [ ] Create Mix task `lib/mix/tasks/c_u_l8er.certs.ex`
  - [ ] `mix c_u_l8er.certs.init` - Create CA
  - [ ] `mix c_u_l8er.certs.list` - List issued certs
  - [ ] `mix c_u_l8er.certs.export CA_PATH` - Export CA for browser
  - [ ] `mix c_u_l8er.certs.renew DOMAIN` - Manually renew

- [ ] Write tests `test/c_u_l8er/security/certificates_test.exs`

### Part 3: Network Security (3-5 hours)

- [ ] Create `lib/c_u_l8er/security/network.ex`
  - [ ] `Firewall` module
  - [ ] `configure_zones/2` - Set up network zones
  - [ ] `apply_rules/2` - Apply firewall rules to Incus
  - [ ] `create_bridge/2` - Create isolated network bridge
  - [ ] `attach_to_zone/3` - Attach container to zone

- [ ] Update `lib/c_u_l8er/dsl/infrastructure.ex`
  - [ ] Add `network_zone` attribute to resources
  - [ ] Add `zone` block to topology
  - [ ] Define allowed traffic between zones

- [ ] Update `lib/c_u_l8er/core/incus.ex`
  - [ ] `create_network/3` - Create Incus network
  - [ ] `attach_network/4` - Attach container to network
  - [ ] `set_firewall_rules/3` - Configure iptables in container

- [ ] Write tests `test/c_u_l8er/security/network_test.exs`

### Part 4: Container Security (2-4 hours)

- [ ] Create `lib/c_u_l8er/security/container.ex`
  - [ ] `SecurityProfile` struct
  - [ ] `apply_profile/3` - Apply security settings to container
  - [ ] `set_user/3` - Configure non-root user
  - [ ] `set_readonly/2` - Make root filesystem read-only
  - [ ] `drop_capabilities/3` - Drop Linux capabilities

- [ ] Update `lib/c_u_l8er/dsl/configuration.ex`
  - [ ] Add `security` block
  - [ ] `user uid: X, gid: Y`
  - [ ] `read_only_root true`
  - [ ] `capabilities [:CAP1, :CAP2]`

- [ ] Update `lib/c_u_l8er/core/executor.ex`
  - [ ] Apply security profile during creation
  - [ ] Configure Incus security features

- [ ] Write tests `test/c_u_l8er/security/container_test.exs`

### Part 5: Audit Logging (2-3 hours)

- [ ] Create `lib/c_u_l8er/security/audit.ex`
  - [ ] `AuditLogger` GenServer
  - [ ] `log/3` - Log audit event
  - [ ] `configure_backends/1` - Set up log destinations
  - [ ] `rotate_logs/0` - Rotate log files
  - [ ] `query/2` - Query audit log

- [ ] Update `lib/c_u_l8er/core/executor.ex`
  - [ ] Add audit logging to all operations
  - [ ] Log: deployment start/end, failures, rollbacks

- [ ] Create Mix task `lib/mix/tasks/c_u_l8er.audit.ex`
  - [ ] `mix c_u_l8er.audit.tail` - Tail audit log
  - [ ] `mix c_u_l8er.audit.query EVENT` - Search logs
  - [ ] `mix c_u_l8er.audit.export` - Export logs

- [ ] Write tests `test/c_u_l8er/security/audit_test.exs`

---

## Code Examples

### Secrets Management

**DSL Usage:**
```elixir
topology :homelab do
  secrets do
    backend :encrypted_file
    key_source :system_env  # Reads MASTER_KEY env var
    storage_path "~/.c_u_l8er/secrets/"
  end
  
  resource :web do
    environment do
      set :MIX_ENV, "prod"
      # Secret stored encrypted, decrypted at runtime
      secret :DATABASE_URL, from: :secret_store, key: "homelab/db_url"
      secret :SECRET_KEY_BASE, from: :secret_store, key: "homelab/secret_key"
    end
  end
end
```

**Implementation:**
```elixir
defmodule CUL8er.Security.Secrets do
  use GenServer
  
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end
  
  def store(topology, key, value) do
    GenServer.call(__MODULE__, {:store, topology, key, value})
  end
  
  def retrieve(topology, key) do
    GenServer.call(__MODULE__, {:retrieve, topology, key})
  end
  
  # Implementation
  def init(opts) do
    master_key = System.get_env("MASTER_KEY") || 
                 raise "MASTER_KEY not set"
    
    storage_path = Keyword.get(opts, :storage_path, 
                               Path.expand("~/.c_u_l8er/secrets"))
    
    File.mkdir_p!(storage_path)
    
    {:ok, %{
      master_key: master_key,
      storage_path: storage_path
    }}
  end
  
  def handle_call({:store, topology, key, value}, _from, state) do
    # Encrypt value
    encrypted = encrypt(value, state.master_key)
    
    # Store to file
    path = Path.join([state.storage_path, topology, key])
    File.mkdir_p!(Path.dirname(path))
    File.write!(path, encrypted)
    
    {:reply, :ok, state}
  end
  
  def handle_call({:retrieve, topology, key}, _from, state) do
    # Read encrypted file
    path = Path.join([state.storage_path, topology, key])
    
    case File.read(path) do
      {:ok, encrypted} ->
        # Decrypt
        decrypted = decrypt(encrypted, state.master_key)
        {:reply, {:ok, decrypted}, state}
      
      {:error, _} = error ->
        {:reply, error, state}
    end
  end
  
  defp encrypt(plaintext, key) do
    # AES-256-GCM encryption
    :crypto.crypto_one_time_aead(
      :aes_256_gcm,
      key,
      :crypto.strong_rand_bytes(12),  # IV
      plaintext,
      "",  # AAD
      true  # Encrypt
    )
  end
  
  defp decrypt(ciphertext, key) do
    # AES-256-GCM decryption
    # Implementation here
  end
end
```

**Mix Task:**
```elixir
defmodule Mix.Tasks.CUL8er.Secret do
  use Mix.Task
  
  @shortdoc "Manage secrets"
  
  def run(["set", key]) do
    Mix.Task.run("app.start")
    
    # Read secret from stdin (won't echo)
    IO.puts("Enter secret value (input hidden):")
    value = IO.gets("") |> String.trim()
    
    CUL8er.Security.Secrets.store("homelab", key, value)
    IO.puts("✓ Secret stored: #{key}")
  end
  
  def run(["list"]) do
    Mix.Task.run("app.start")
    
    secrets = CUL8er.Security.Secrets.list("homelab")
    
    IO.puts("\nStored secrets:")
    Enum.each(secrets, fn key ->
      IO.puts("  - #{key}")
    end)
  end
end
```

---

### Certificate Management

**DSL Usage:**
```elixir
topology :homelab do
  certificates do
    provider :self_signed_ca
    ca_name "Homelab Root CA"
    validity_years 10
  end
  
  resource :web do
    network do
      expose port: 4000, as: 443, protocol: :https do
        certificate domain: "web.homelab.local"
      end
    end
  end
end
```

**Implementation:**
```elixir
defmodule CUL8er.Security.Certificates.CA do
  @moduledoc "Manages self-signed certificate authority"
  
  def generate_ca(opts) do
    name = Keyword.fetch!(opts, :ca_name)
    validity_days = Keyword.get(opts, :validity_years, 10) * 365
    
    # Generate CA private key
    ca_key = :public_key.generate_key({:rsa, 4096, 65537})
    
    # Create CA certificate
    ca_cert = :public_key.pkix_sign(
      create_cert_template(name, validity_days, :ca),
      ca_key
    )
    
    # Store CA
    storage_path = Path.expand("~/.c_u_l8er/ca")
    File.mkdir_p!(storage_path)
    
    File.write!(
      Path.join(storage_path, "ca.key"),
      :public_key.pem_encode([{:RSAPrivateKey, ca_key}])
    )
    
    File.write!(
      Path.join(storage_path, "ca.crt"),
      :public_key.pem_encode([{:Certificate, ca_cert}])
    )
    
    {:ok, ca_cert}
  end
  
  def generate_cert(domain, opts) do
    # Load CA
    ca_key = load_ca_key()
    ca_cert = load_ca_cert()
    
    # Generate certificate key
    cert_key = :public_key.generate_key({:rsa, 2048, 65537})
    
    # Create certificate
    cert = :public_key.pkix_sign(
      create_cert_template(domain, 365, :server),
      ca_key
    )
    
    # Store certificate
    store_cert(domain, cert_key, cert)
    
    {:ok, cert}
  end
  
  defp create_cert_template(subject, validity_days, type) do
    # Certificate template creation
    # Implementation here
  end
end
```

---

### Network Security

**DSL Usage:**
```elixir
topology :homelab do
  network do
    zone :dmz do
      resources [:web]
      allow_from ["192.168.1.0/24"]  # Your LAN
    end
    
    zone :internal do
      resources [:database]
      allow_from :containers  # Only from other containers
    end
  end
  
  resource :database do
    network_zone :internal
    network do
      expose port: 5432, to: :containers_only
    end
  end
  
  resource :web do
    network_zone :dmz
    network do
      expose port: 4000, to: :lan
    end
  end
end
```

**Implementation:**
```elixir
defmodule CUL8er.Security.Network do
  @moduledoc "Network isolation and firewall management"
  
  def configure_zones(host, topology) do
    zones = topology.network.zones
    
    Enum.each(zones, fn zone ->
      # Create isolated network bridge
      create_zone_network(host, zone)
      
      # Apply firewall rules
      apply_zone_rules(host, zone)
    end)
  end
  
  defp create_zone_network(host, zone) do
    network_name = "cul8er-#{zone.name}"
    
    # Create Incus network
    CUL8er.Core.Incus.execute(host, """
      incus network create #{network_name} \
        ipv4.address=#{zone.cidr} \
        ipv4.nat=false \
        ipv6.address=none
    """)
  end
  
  defp apply_zone_rules(host, zone) do
    # Configure iptables rules
    rules = generate_firewall_rules(zone)
    
    Enum.each(rules, fn rule ->
      CUL8er.Core.Incus.execute(host, """
        incus network set #{zone.name} \
          raw.iptables="#{rule}"
      """)
    end)
  end
end
```

---

### Container Security

**DSL Usage:**
```elixir
topology :homelab do
  security do
    defaults do
      user uid: 1000, gid: 1000
      read_only_root true
      capabilities :drop_all
    end
  end
  
  resource :web do
    security do
      user uid: 1000
      read_only_root true
      capabilities [:NET_BIND_SERVICE]  # Only if binding to port <1024
    end
    
    # Writable volumes where needed
    storage do
      volume :tmp, mount: "/tmp", writable: true
    end
  end
end
```

**Implementation:**
```elixir
defmodule CUL8er.Security.Container do
  @moduledoc "Container security hardening"
  
  defstruct [
    :uid,
    :gid,
    :read_only_root,
    :capabilities,
    :resource_limits
  ]
  
  def apply_profile(host, container_name, profile) do
    # Set user/group
    if profile.uid do
      set_user(host, container_name, profile.uid, profile.gid)
    end
    
    # Make root read-only
    if profile.read_only_root do
      set_readonly_root(host, container_name)
    end
    
    # Drop capabilities
    if profile.capabilities do
      configure_capabilities(host, container_name, profile.capabilities)
    end
  end
  
  defp set_user(host, container, uid, gid) do
    CUL8er.Core.Incus.execute(host, """
      incus config set #{container} \
        security.idmap.isolated=true \
        raw.idmap="both #{uid} #{gid}"
    """)
  end
  
  defp set_readonly_root(host, container) do
    CUL8er.Core.Incus.execute(host, """
      incus config set #{container} \
        security.protection.shift=true
    """)
  end
  
  defp configure_capabilities(host, container, caps) do
    # Drop all capabilities
    CUL8er.Core.Incus.execute(host, """
      incus config set #{container} \
        linux.kernel_modules=false
    """)
    
    # Add only specified capabilities
    Enum.each(caps, fn cap ->
      CUL8er.Core.Incus.execute(host, """
        incus config set #{container} \
          raw.lxc="lxc.cap.keep=#{cap}"
      """)
    end)
  end
end
```

---

### Audit Logging

**DSL Usage:**
```elixir
topology :homelab do
  audit do
    events [:deployment_started, :deployment_completed, :deployment_failed]
    backends [{:file, path: "~/.c_u_l8er/logs/audit.log"}]
    retention keep_locally: 30
  end
end
```

**Implementation:**
```elixir
defmodule CUL8er.Security.Audit do
  use GenServer
  require Logger
  
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end
  
  def log(event, metadata \\ %{}) do
    GenServer.cast(__MODULE__, {:log, event, metadata})
  end
  
  def init(opts) do
    log_path = Keyword.get(opts, :log_path, 
                           Path.expand("~/.c_u_l8er/logs/audit.log"))
    
    File.mkdir_p!(Path.dirname(log_path))
    
    {:ok, file} = File.open(log_path, [:append, :utf8])
    
    {:ok, %{
      file: file,
      log_path: log_path
    }}
  end
  
  def handle_cast({:log, event, metadata}, state) do
    entry = %{
      timestamp: DateTime.utc_now(),
      event: event,
      metadata: metadata,
      user: System.get_env("USER"),
      hostname: get_hostname()
    }
    
    # Write to file
    IO.write(state.file, Jason.encode!(entry) <> "\n")
    
    # Also log to console
    Logger.info("[AUDIT] #{event}", metadata)
    
    {:noreply, state}
  end
  
  defp get_hostname do
    {hostname, 0} = System.cmd("hostname", [])
    String.trim(hostname)
  end
end
```

**Integration in Executor:**
```elixir
defmodule CUL8er.Core.Executor do
  alias CUL8er.Security.Audit
  
  def deploy(topology, opts) do
    Audit.log(:deployment_started, %{
      topology: topology.name,
      resources: length(topology.resources)
    })
    
    try do
      result = do_deploy(topology, opts)
      
      Audit.log(:deployment_completed, %{
        topology: topology.name,
        duration_ms: result.duration
      })
      
      result
    rescue
      error ->
        Audit.log(:deployment_failed, %{
          topology: topology.name,
          error: inspect(error)
        })
        
        reraise error, __STACKTRACE__
    end
  end
end
```

---

## Testing Strategy

### Unit Tests

```elixir
# test/c_u_l8er/security/secrets_test.exs
defmodule CUL8er.Security.SecretsTest do
  use ExUnit.Case
  
  setup do
    # Set test master key
    System.put_env("MASTER_KEY", "test_key_32_bytes_long_minimum!")
    
    # Use temp directory
    storage_path = Path.join(System.tmp_dir!(), "test_secrets")
    File.rm_rf!(storage_path)
    
    start_supervised!({CUL8er.Security.Secrets, storage_path: storage_path})
    
    %{storage_path: storage_path}
  end
  
  test "stores and retrieves secrets" do
    :ok = CUL8er.Security.Secrets.store("test", "key1", "secret_value")
    
    assert {:ok, "secret_value"} = 
      CUL8er.Security.Secrets.retrieve("test", "key1")
  end
  
  test "secrets are encrypted on disk", %{storage_path: path} do
    CUL8er.Security.Secrets.store("test", "key1", "secret_value")
    
    # Read raw file
    file_path = Path.join([path, "test", "key1"])
    {:ok, content} = File.read(file_path)
    
    # Should NOT contain plaintext
    refute content =~ "secret_value"
  end
end
```

### Integration Tests

```elixir
# test/integration/security_test.exs
@moduletag :integration

defmodule CUL8er.Integration.SecurityTest do
  use ExUnit.Case
  
  test "deploys with encrypted secrets" do
    # Define topology with secrets
    defmodule TestTopology do
      use CUL8er
      
      topology :test do
        secrets do
          backend :encrypted_file
          key_source :system_env
        end
        
        resource :web do
          environment do
            secret :TEST_SECRET, from: :secret_store, key: "test/secret"
          end
        end
      end
    end
    
    # Store secret
    CUL8er.Security.Secrets.store("test", "test/secret", "my_secret")
    
    # Deploy
    {:ok, _} = TestTopology.deploy(:test)
    
    # Verify secret is in container environment
    {:ok, env} = CUL8er.Core.Incus.exec("localhost", "web", "env")
    assert env =~ "TEST_SECRET=my_secret"
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
        
        resource :web do
          # Uses default security
        end
      end
    end
    
    {:ok, _} = TestTopology.deploy(:test)
    
    # Check container user
    {:ok, user} = CUL8er.Core.Incus.exec("localhost", "web", "id -u")
    assert String.trim(user) == "1000"
  end
end
```

---

## Deliverables

After completing Phase 2.5, you should have:

- [ ] Encrypted secrets stored in `~/.c_u_l8er/secrets/`
- [ ] Self-signed CA in `~/.c_u_l8er/ca/`
- [ ] Network zones configured
- [ ] Containers running as non-root with read-only root
- [ ] Audit log in `~/.c_u_l8er/logs/audit.log`
- [ ] Mix tasks for secret/cert management
- [ ] All security tests passing

### File Structure

```
lib/c_u_l8er/
├── security/
│   ├── secrets.ex                 # ✓ Secrets management
│   ├── secrets/
│   │   ├── backend.ex             # ✓ Backend behaviour
│   │   └── encrypted_file.ex      # ✓ File storage
│   ├── certificates.ex            # ✓ Cert management
│   ├── certificates/
│   │   ├── ca.ex                  # ✓ CA operations
│   │   └── storage.ex             # ✓ Cert storage
│   ├── network.ex                 # ✓ Network zones
│   ├── container.ex               # ✓ Container security
│   └── audit.ex                   # ✓ Audit logging
└── mix/tasks/
    ├── c_u_l8er.secret.ex         # ✓ Secret CLI
    ├── c_u_l8er.certs.ex          # ✓ Cert CLI
    └── c_u_l8er.audit.ex          # ✓ Audit CLI

~/.c_u_l8er/
├── secrets/                       # Encrypted secrets
│   └── homelab/
│       ├── db_password
│       ├── secret_key_base
│       └── erlang_cookie
├── ca/                           # Certificate authority
│   ├── ca.key
│   ├── ca.crt
│   └── ca.pem
├── certs/                        # Issued certificates
│   └── web.homelab.local/
│       ├── cert.crt
│       └── cert.key
└── logs/                         # Audit logs
    └── audit.log
```

---

## Success Criteria

Before moving to Phase 3, verify:

- [ ] `mix c_u_l8er.secret.set test` works
- [ ] `mix c_u_l8er.secret.get test` retrieves secret
- [ ] `mix c_u_l8er.certs.init` creates CA
- [ ] Browser trusts CA after import
- [ ] Containers get isolated networks
- [ ] Containers run as non-root
- [ ] `ps aux` in container shows UID 1000
- [ ] Audit log captures deployments
- [ ] All tests pass: `mix test`
- [ ] Integration tests pass: `mix test --only integration`

---

## Common Issues & Solutions

### Issue: "MASTER_KEY not set"

**Solution:**
```bash
# Generate and export key
export MASTER_KEY=$(openssl rand -hex 32)
echo "export MASTER_KEY='$MASTER_KEY'" >> ~/.bashrc
source ~/.bashrc
```

### Issue: "Browser doesn't trust certificate"

**Solution:**
```bash
# Export CA certificate
mix c_u_l8er.certs.export ~/Downloads/homelab-ca.crt

# Import in browser:
# Chrome: Settings → Privacy → Manage Certificates → Authorities → Import
# Firefox: Preferences → Privacy → Certificates → Import
```

### Issue: "Container can't write to /tmp"

**Solution:**
```elixir
# Add writable volume
resource :web do
  security do
    read_only_root true
  end
  
  storage do
    volume :tmp, mount: "/tmp", writable: true
  end
end
```

### Issue: "Permission denied binding to port 443"

**Solution:**
```elixir
# Add NET_BIND_SERVICE capability
resource :web do
  security do
    capabilities [:NET_BIND_SERVICE]
  end
end
```

---

## Next Steps

After Phase 2.5 is complete:

1. **Test your security setup:**
   ```bash
   mix c_u_l8er.deploy homelab
   curl https://web.homelab.local  # Should work with HTTPS
   ```

2. **Proceed to Phase 3:** Deployment Strategies
   - Now you have secrets for database passwords
   - Now you have HTTPS for health checks
   - Now you have audit logs for rollback decisions

3. **Optional enhancements:**
   - Add secret rotation script
   - Set up automatic cert renewal
   - Configure log rotation

---

## Time Budget

| Task | Estimated Hours | Priority |
|------|----------------|----------|
| Secrets Management | 6-8h | CRITICAL |
| Certificate Management | 5-6h | HIGH |
| Network Security | 3-5h | HIGH |
| Container Security | 2-4h | MEDIUM |
| Audit Logging | 2-3h | MEDIUM |
| Testing | 2-3h | HIGH |
| **TOTAL** | **20-29h** | - |

**Recommended:** Spread over 1.5-2 weeks alongside Phase 3 prep

---

## Summary

Phase 2.5 adds production-ready security to C U L8er:

✅ **Secrets never in git** (encrypted at rest)  
✅ **HTTPS everywhere** (self-signed CA)  
✅ **Network isolation** (zone-based firewall)  
✅ **Container hardening** (non-root, read-only)  
✅ **Audit trail** (know what happened)

This gives you a **secure foundation** for the deployment strategies in Phase 3 and beyond. Security is built-in, not bolted-on.

**Status after Phase 2.5:** Production-ready for homelab deployments! 🔒
