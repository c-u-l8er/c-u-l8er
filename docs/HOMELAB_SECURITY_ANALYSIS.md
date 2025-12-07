# Security Layers for Homelab Deployment
*Linux Laptop + 3 Node Homelab Analysis*

## Environment Context

**Setup:**
- 1x Development laptop (Arch Linux)
- 3x Homelab nodes (likely Ubuntu/Debian/Arch)
- Local network (192.168.x.x or 10.0.x.x)
- No external exposure (or minimal via reverse proxy)
- Personal/learning use case

**Security Profile:**
- Threat level: LOW to MEDIUM
- Compliance requirements: NONE
- Budget: $0 (free tools only)
- Complexity tolerance: LOW to MEDIUM
- Time budget: Reasonable (not enterprise-level effort)

---

## Security Layer Recommendations

### ✅ MUST HAVE (Critical for Homelab)

| Layer | Priority | Reason | Implementation Effort |
|-------|----------|--------|----------------------|
| **Secrets Management** | CRITICAL | Never commit passwords/API keys | 5-8 hours |
| **Certificate Management** | HIGH | Enable HTTPS, avoid browser warnings | 4-6 hours |
| **Basic Network Security** | HIGH | Prevent containers from accessing everything | 3-5 hours |
| **Container Security Basics** | MEDIUM | Run as non-root, basic isolation | 2-4 hours |
| **Basic Audit Logging** | MEDIUM | Know what happened when things break | 2-3 hours |

**Total Effort: 16-26 hours** (reasonable for homelab)

### ⚠️ NICE TO HAVE (Add Later)

| Layer | Priority | Reason | When to Add |
|-------|----------|--------|-------------|
| **Advanced Network Zones** | LOW | Overkill for 3 nodes | When expanding to 10+ nodes |
| **RBAC/MFA** | LOW | You're the only user | When sharing access |
| **Compliance Frameworks** | NONE | Not needed for homelab | Never (unless selling services) |
| **Image Scanning** | LOW | Trust your own images | When pulling unknown images |
| **Incident Response** | LOW | You ARE the incident response | When running critical services |

### ❌ SKIP (Not Worth It for Homelab)

| Layer | Reason |
|-------|--------|
| **SOC2/PCI Compliance** | Not applicable |
| **SIEM Integration** | Overkill, too complex |
| **Advanced IDS (Falco)** | Resource-intensive, unnecessary |
| **Multi-region HA** | You have 3 nodes in one room |
| **Enterprise IAM** | You're the only user |

---

## Recommended Security Stack for Homelab

### Layer 1: Secrets Management (MUST HAVE)

**Recommendation: Encrypted File Backend**

```elixir
topology :homelab do
  secrets do
    # Simple encrypted file - no Vault needed
    backend :encrypted_file
    key_source :system_env  # MASTER_KEY from ~/.bashrc
    storage_path "~/.c_u_l8er/secrets/"
    
    # Optional: use pass (password store)
    # backend :password_store
    # prefix "c_u_l8er/"
  end
  
  resource :web do
    environment do
      secret :SECRET_KEY_BASE, from: :secret_store, key: "homelab/secret_key"
      secret :DATABASE_PASSWORD, from: :secret_store, key: "homelab/db_pass"
    end
  end
end
```

**Why This Works:**
- ✅ Secrets never in git
- ✅ Encrypted on disk
- ✅ Easy to backup
- ✅ No external dependencies
- ✅ Good enough for homelab

**Effort:** 5-8 hours

---

### Layer 2: Certificate Management (MUST HAVE)

**Recommendation: Self-Signed CA + mDNS**

```elixir
topology :homelab do
  certificates do
    # Create your own CA (one-time)
    provider :self_signed_ca
    ca_name "Homelab Root CA"
    validity_years 10
    
    # Auto-generate certs for services
    domain "web.local" do
      auto_renew true
      renew_before_days 30
    end
    
    domain "*.homelab.local" do
      wildcard true
    end
    
    # Optional: Let's Encrypt if you expose services
    # provider :letsencrypt
    # email "your@email.com"
    # dns_challenge true  # For local DNS
  end
  
  resource :web do
    network do
      expose port: 4000, as: 443, protocol: :https do
        certificate domain: "web.homelab.local"
        # Browser will trust after importing CA cert once
      end
    end
  end
end
```

**Why This Works:**
- ✅ HTTPS everywhere (good practice)
- ✅ No browser warnings (after CA import)
- ✅ Free
- ✅ Works offline
- ✅ mDNS (.local domains)

**Effort:** 4-6 hours

---

### Layer 3: Basic Network Security (MUST HAVE)

**Recommendation: Simple Firewall Rules**

```elixir
topology :homelab do
  network do
    # Default: containers can talk to each other
    default_policy :allow_local
    
    # Simple zones
    zone :dmz do
      # Services exposed to your LAN
      resources [:web, :monitoring]
      
      allow_from ["192.168.1.0/24"]  # Your home network
      deny_from :internet  # If port-forwarded
    end
    
    zone :internal do
      # Backend services
      resources [:database, :cache]
      
      # Only accessible from other containers
      allow_from :containers
      deny_from :lan
    end
    
    # Basic rate limiting (prevent accidents)
    rate_limiting do
      limit 100, per: :second, scope: :ip
      burst 200
    end
  end
  
  resource :database do
    network do
      # Don't expose DB to LAN
      expose port: 5432, to: :containers_only
    end
  end
  
  resource :web do
    network do
      # Expose to LAN
      expose port: 4000, to: :lan
    end
  end
end
```

**Why This Works:**
- ✅ Prevents accidental exposure
- ✅ Isolates sensitive services
- ✅ Simple to understand
- ✅ Good security hygiene

**Effort:** 3-5 hours

---

### Layer 4: Container Security Basics (RECOMMENDED)

**Recommendation: Non-root + Read-only Root**

```elixir
topology :homelab do
  security do
    # Default security profile for all containers
    defaults do
      # Run as non-root
      user uid: 1000, gid: 1000
      
      # Read-only root filesystem
      read_only_root true
      
      # Drop unnecessary capabilities
      capabilities :drop_all
      add_capabilities [:NET_BIND_SERVICE]  # Only if needed
      
      # Basic resource limits
      limits do
        pids max: 100
        files max_open: 1024
      end
    end
  end
  
  resource :web do
    # Inherits defaults, can override
    security do
      user uid: 1000  # Your user
      read_only_root true
    end
    
    # Writable volumes where needed
    storage do
      volume :tmp, mount: "/tmp", writable: true
      volume :uploads, mount: "/app/uploads", writable: true
    end
  end
end
```

**Why This Works:**
- ✅ Prevents container breakout
- ✅ Limits blast radius
- ✅ Easy to implement
- ✅ Minimal overhead

**Effort:** 2-4 hours

---

### Layer 5: Basic Audit Logging (RECOMMENDED)

**Recommendation: Simple File Logging**

```elixir
topology :homelab do
  audit do
    # Log important events
    events [
      :deployment_started,
      :deployment_completed,
      :deployment_failed,
      :deployment_rolled_back,
      :secret_accessed,
      :topology_modified,
      :resource_created,
      :resource_destroyed,
    ]
    
    # Simple file backend
    backends [
      {:file, path: "~/.c_u_l8er/logs/audit.log", rotate: :daily},
    ]
    
    # Keep 30 days locally
    retention do
      keep_locally days: 30
      compress_after_days 7
    end
  end
end
```

**Why This Works:**
- ✅ Know what happened
- ✅ Debug deployments
- ✅ Simple to implement
- ✅ Low overhead

**Effort:** 2-3 hours

---

## Homelab Security Profile

### Complete Example

```elixir
defmodule Homelab.Infrastructure do
  use CUL8er
  
  topology :homelab do
    # ============================================================
    # SECRETS - Encrypted file backend
    # ============================================================
    secrets do
      backend :encrypted_file
      key_source :system_env
      storage_path "~/.c_u_l8er/secrets/"
    end
    
    # ============================================================
    # CERTIFICATES - Self-signed CA
    # ============================================================
    certificates do
      provider :self_signed_ca
      ca_name "Homelab Root CA"
      validity_years 10
      
      domain "*.homelab.local" do
        auto_renew true
      end
    end
    
    # ============================================================
    # NETWORK - Basic firewall
    # ============================================================
    network do
      default_policy :allow_local
      
      zone :dmz do
        resources [:web, :monitoring]
        allow_from ["192.168.1.0/24"]
      end
      
      zone :internal do
        resources [:database]
        allow_from :containers
      end
    end
    
    # ============================================================
    # SECURITY - Non-root defaults
    # ============================================================
    security do
      defaults do
        user uid: 1000, gid: 1000
        read_only_root true
        capabilities :drop_all
      end
    end
    
    # ============================================================
    # AUDIT - Simple logging
    # ============================================================
    audit do
      events [:deployment_started, :deployment_completed, :deployment_failed]
      backends [{:file, path: "~/.c_u_l8er/logs/audit.log"}]
      retention keep_locally: 30
    end
    
    # ============================================================
    # INFRASTRUCTURE - 3 nodes + laptop
    # ============================================================
    host :laptop do
      address "localhost"
      platform :arch_linux
    end
    
    host :node1 do
      address "192.168.1.101"
      platform :ubuntu
    end
    
    host :node2 do
      address "192.168.1.102"
      platform :ubuntu
    end
    
    host :node3 do
      address "192.168.1.103"
      platform :ubuntu
    end
    
    # ============================================================
    # RESOURCES
    # ============================================================
    resource :database, type: :container, on: :node1 do
      from_image "images:postgres/14"
      
      network do
        expose port: 5432, to: :containers_only
      end
      
      storage do
        volume :data, mount: "/var/lib/postgresql/data", writable: true
      end
      
      environment do
        secret :POSTGRES_PASSWORD, from: :secret_store, key: "homelab/db_pass"
      end
    end
    
    resource :web, type: :container, on: :node2 do
      from_image "images:alpine/3.19"
      
      network do
        expose port: 4000, as: 443, protocol: :https do
          certificate domain: "web.homelab.local"
        end
      end
      
      environment do
        secret :DATABASE_URL, from: :secret_store, key: "homelab/db_url"
        secret :SECRET_KEY_BASE, from: :secret_store, key: "homelab/secret_key"
      end
      
      storage do
        volume :uploads, mount: "/app/uploads", writable: true
      end
    end
    
    resource :monitoring, type: :container, on: :node3 do
      from_image "images:grafana"
      
      network do
        expose port: 3000, protocol: :http
      end
    end
    
    # ============================================================
    # CLUSTER
    # ============================================================
    cluster :homelab_cluster do
      nodes [:web]
      discovery strategy: Cluster.Strategy.Epmd
      cookie from: :secret_store, key: "homelab/erlang_cookie"
    end
    
    # ============================================================
    # DEPLOYMENT
    # ============================================================
    strategy do
      approach :rolling
      max_parallel 1
      
      healthcheck do
        endpoint "https://web.homelab.local/health"
        interval seconds: 10
      end
      
      rollback do
        on_failure :automatic
        snapshot true
      end
    end
  end
end
```

---

## Quick Setup Guide

### 1. Generate Master Key

```bash
# Generate encryption key for secrets
export MASTER_KEY=$(openssl rand -hex 32)
echo "export MASTER_KEY='$MASTER_KEY'" >> ~/.bashrc

# Or use pass (password-store)
pass generate c_u_l8er/master_key 32
```

### 2. Create CA Certificate

```bash
# Generate CA (one-time setup)
mix c_u_l8er.security.init_ca

# Import CA into browsers
# Chrome: Settings -> Privacy -> Manage Certificates -> Authorities -> Import
# Firefox: Preferences -> Privacy -> View Certificates -> Authorities -> Import

# File will be at: ~/.c_u_l8er/ca/homelab-ca.crt
```

### 3. Store First Secret

```bash
# Store database password
mix c_u_l8er.secret.set homelab/db_pass

# Or manually
echo -n "my-secret-password" | \
  openssl enc -aes-256-cbc -salt -pbkdf2 \
  -out ~/.c_u_l8er/secrets/homelab/db_pass.enc \
  -pass env:MASTER_KEY
```

### 4. Configure Firewall (on nodes)

```bash
# On each node
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow from 192.168.1.0/24  # Your LAN
sudo ufw enable
```

### 5. Deploy!

```bash
mix c_u_l8er.deploy homelab
```

---

## What You Get

### Security Benefits
- ✅ Secrets encrypted at rest
- ✅ HTTPS everywhere (no warnings)
- ✅ Database not exposed to LAN
- ✅ Containers isolated
- ✅ Audit trail of deployments
- ✅ Non-root containers

### Minimal Overhead
- ⚡ No external services required
- ⚡ Low resource usage
- ⚡ Simple to maintain
- ⚡ Easy to backup (just ~/.c_u_l8er/)

### Good Security Posture
- 🛡️ Prevents common mistakes
- 🛡️ Follows best practices
- 🛡️ Room to grow (can add more layers later)
- 🛡️ Production-ready patterns

---

## When to Add More Security

### Add RBAC/MFA When:
- You share access with others
- You expose services to internet
- You run services for others

### Add Image Scanning When:
- You pull images from Docker Hub
- You don't build your own images
- You run untrusted workloads

### Add Advanced Monitoring When:
- You have >10 nodes
- You run critical services
- You need compliance

### Add Vault When:
- You have >50 secrets
- You need automated rotation
- You have multiple environments (dev/staging/prod)

---

## Backup Strategy

```bash
# Backup everything important
tar czf c_u_l8er-backup-$(date +%Y%m%d).tar.gz \
  ~/.c_u_l8er/secrets/ \
  ~/.c_u_l8er/ca/ \
  ~/.c_u_l8er/state/ \
  ~/.c_u_l8er/logs/

# Store somewhere safe (encrypted USB drive, cloud storage)
```

---

## Cost Analysis

| Component | Enterprise | Homelab |
|-----------|-----------|---------|
| Secrets Management | Vault ($$$) | Encrypted files (Free) |
| Certificates | Let's Encrypt (Free) or Commercial ($) | Self-signed CA (Free) |
| Monitoring | Datadog ($$$) | Grafana (Free) |
| Log Storage | Splunk ($$$) | Local files (Free) |
| Compliance | Auditors ($$$) | Not needed (Free) |
| **TOTAL** | **$5k-50k/year** | **$0/year** |

---

## Summary

**Recommended Security Stack for Homelab:**

1. ✅ Secrets: Encrypted file backend (5-8h)
2. ✅ Certificates: Self-signed CA (4-6h)
3. ✅ Network: Basic firewall rules (3-5h)
4. ✅ Containers: Non-root + read-only (2-4h)
5. ✅ Audit: Simple file logging (2-3h)

**Total Implementation Time: 16-26 hours**

**Security Level: GOOD (appropriate for homelab)**

This gives you 80% of the security benefit with 20% of the effort. Perfect for a homelab where you're learning, experimenting, and running personal services.

You can always add more layers later as your needs grow!
