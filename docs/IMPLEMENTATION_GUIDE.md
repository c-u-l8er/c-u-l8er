# C U L8er - Complete Implementation Guide

**Project:** C U L8er (Computer Units Load-8alancer)  
**URL:** https://c-u-l8er.link  
**Goal:** Production-ready Elixir deployment system in 10 weeks

---

## Project Overview

C U L8er is an Elixir-native deployment system for distributed BEAM applications. It provides:

- **Single, clean DSL** with semantic layer separation
- **Incus-powered** container and VM management  
- **Automatic BEAM clustering** with libcluster
- **Zero-downtime deployments** (rolling, blue-green, canary)
- **Built-in observability** with metrics and health checking

**No backwards compatibility** - one design, done right from the start.

---

## Timeline Overview

| Phase | Duration | Focus | Deliverable |
|-------|----------|-------|-------------|
| **Phase 1** | Weeks 1-2 | Core DSL & macros | Working DSL that parses topologies |
| **Phase 2** | Weeks 3-4 | Incus integration & state | Real deployments create containers |
| **Phase 3** | Weeks 5-6 | Deployment strategies | Zero-downtime updates with health checks |
| **Phase 4** | Weeks 7-8 | Clustering & observability | Automatic node discovery + metrics |
| **Phase 5** | Weeks 9-10 | Testing & release | Production-ready v0.1.0 |

**Total Time:** 200-250 hours (10 weeks part-time or 5 weeks full-time)

---

## Phase-by-Phase Breakdown

### Phase 1: Core DSL & Infrastructure (Weeks 1-2)

**Files:** [PHASE_1_PROMPT.md](PHASE_1_PROMPT.md)

**What You Build:**
```elixir
topology :prod do
  host :server do
    address "10.0.1.100"
    platform :icusos
  end
  
  resource :web, type: :container, on: :server do
    from_image "images:alpine/3.19"
    limits do
      cpu cores: 2
      memory gigabytes: 2
    end
  end
end

# This compiles and parses into data structures
```

**Key Deliverables:**
- ✅ Macro system that compiles without errors
- ✅ All four DSL layers (Infrastructure, Configuration, Strategy, Cluster)
- ✅ Data structures build correctly
- ✅ Basic test suite

**Time:** 40-50 hours

---

### Phase 2: Incus Integration & State Management (Weeks 3-4)

**Files:** [PHASE_2_PROMPT.md](PHASE_2_PROMPT.md)

**What You Build:**
```elixir
# This actually creates a container:
MyTopology.deploy(:production)

# This tracks what's deployed:
MyTopology.status(:production)

# This shows planned changes:
MyTopology.plan(:production)
```

**Key Deliverables:**
- ✅ Real Incus CLI integration (`System.cmd`)
- ✅ SSH client for remote hosts
- ✅ State management with file/DB backend
- ✅ Plan/apply workflow like Terraform
- ✅ Integration tests with real containers

**Time:** 40-50 hours

---

### Phase 3: Deployment Strategies & Health Checking (Weeks 5-6)

**Files:** [PHASE_3_PROMPT.md](PHASE_3_PROMPT.md)

**What You Build:**
```elixir
strategy do
  approach :rolling
  batch_size 1
  
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

# Zero-downtime deployment with automatic rollback
MyApp.deploy(:production, version: "1.1.0")
```

**Key Deliverables:**
- ✅ Rolling deployment strategy
- ✅ Blue-green deployment strategy
- ✅ Canary deployment strategy
- ✅ HTTP/TCP/command health checks
- ✅ Automatic rollback with snapshots

**Time:** 40-50 hours

---

### Phase 4: Clustering & Observability (Weeks 7-8)

**Files:** [PHASE_4_PROMPT.md](PHASE_4_PROMPT.md)

**What You Build:**
```elixir
cluster :my_app do
  nodes [:web_1, :web_2, :web_3]
  discovery strategy: Cluster.Strategy.Epmd
  cookie from: :system, key: "RELEASE_COOKIE"
end

observability do
  metrics [:deployment_duration, :cluster_size]
  events [:node_joined, :health_check_failed]
end

# Nodes automatically discover each other and form cluster
MyApp.deploy(:production)

# Real-time metrics
CUL8er.Observable.Metrics.snapshot(:production)
```

**Key Deliverables:**
- ✅ Automatic cluster formation with libcluster
- ✅ Node discovery and connection management
- ✅ Telemetry integration for metrics
- ✅ Event bus for real-time updates
- ✅ CLI tools for monitoring

**Time:** 40-50 hours

---

### Phase 5: Testing, Polish & Release (Weeks 9-10)

**Files:** [PHASE_5_PROMPT.md](PHASE_5_PROMPT.md)

**What You Build:**
- Comprehensive test suite (80%+ coverage)
- Property-based tests
- Performance benchmarks
- Polished CLI with formatting
- Complete HexDocs documentation
- Example applications
- Package published to Hex.pm

**Key Deliverables:**
- ✅ All tests passing
- ✅ Documentation complete
- ✅ Published to Hex.pm
- ✅ GitHub repository ready
- ✅ Website live at c-u-l8er.link

**Time:** 40-50 hours

---

## Architecture

### DSL Layer Separation

```
Infrastructure Layer (WHAT exists)
    ↓
Configuration Layer (HOW it's configured)
    ↓
Strategy Layer (WHEN/HOW to deploy)
    ↓
Cluster Layer (HOW nodes communicate)
```

### Module Organization

```
c_u_l8er/
├── lib/
│   ├── c_u_l8er.ex                    # Main entry point
│   ├── c_u_l8er/
│   │   ├── dsl/                      # DSL macros
│   │   │   ├── infrastructure.ex
│   │   │   ├── configuration.ex
│   │   │   ├── strategy.ex
│   │   │   └── cluster.ex
│   │   ├── core/                     # Core functionality
│   │   │   ├── incus.ex
│   │   │   ├── ssh.ex
│   │   │   ├── state.ex
│   │   │   └── executor.ex
│   │   ├── strategies/               # Deployment strategies
│   │   │   ├── rolling.ex
│   │   │   ├── blue_green.ex
│   │   │   └── canary.ex
│   │   ├── cluster/                  # Clustering
│   │   │   ├── manager.ex
│   │   │   └── topology.ex
│   │   └── observable/               # Metrics & monitoring
│   │       ├── metrics.ex
│   │       ├── events.ex
│   │       └── health.ex
│   └── mix/tasks/                    # CLI commands
│       ├── c_u_l8er.deploy.ex
│       ├── c_u_l8er.plan.ex
│       ├── c_u_l8er.status.ex
│       └── c_u_l8er.metrics.ex
└── test/
```

---

## Technology Stack

**Core:**
- Elixir 1.15+
- OTP 26+
- Incus (LXD fork)

**Dependencies:**
- `jason` - JSON encoding/decoding
- `libcluster` - Automatic cluster formation
- `telemetry` - Metrics collection
- `telemetry_metrics` - Metrics aggregation

**Development:**
- `ex_unit` - Testing
- `mox` - Mocking
- `credo` - Code quality
- `dialyxir` - Type checking
- `ex_doc` - Documentation

---

## Key Design Decisions

### Why Single DSL?

**Decision:** Build one clean DSL instead of maintaining multiple approaches

**Reasoning:**
- Clearer mental model for users
- Easier to maintain and evolve
- Better error messages
- Simpler documentation
- Forces good design decisions upfront

### Why Layer Separation?

**Decision:** Separate WHAT/HOW/WHEN/COMMUNICATION into distinct layers

**Reasoning:**
- Inspired by Alkeyword's successful pattern
- Each concern has its own vocabulary
- Easy to understand and reason about
- Simplifies testing
- Supports composition and reuse

### Why Incus?

**Decision:** Build on Incus instead of Docker

**Reasoning:**
- Modern container/VM management (LXD fork)
- Better VM support than Docker
- Growing adoption
- Clean CLI interface
- Good performance

### Why State Management?

**Decision:** Track deployed state like Terraform

**Reasoning:**
- Enables plan/apply workflow
- Drift detection
- Safe updates
- Audit trail
- Rollback support

---

## Success Metrics

**Technical:**
- ✅ Deploy Phoenix app in <30 seconds
- ✅ Form 3-node cluster in <10 seconds
- ✅ Zero-downtime rolling updates
- ✅ 80%+ test coverage
- ✅ <100ms DSL parsing

**User Experience:**
- ✅ Single command deployment
- ✅ Clear error messages
- ✅ Helpful CLI output
- ✅ Complete documentation
- ✅ Example apps work out of box

**Community:**
- 🎯 100 GitHub stars in 3 months
- 🎯 1,000 Hex downloads in 6 months
- 🎯 10 contributors in 6 months
- 🎯 5 production deployments in 6 months

---

## Usage Examples

### Simple Single Container

```elixir
defmodule HelloWorld do
  use CUL8er
  
  topology :simple do
    host :local do
      address "localhost"
      platform :arch_linux
    end
    
    resource :hello, type: :container, on: :local do
      from_image "images:alpine/3.19"
    end
  end
end

HelloWorld.deploy(:simple)
```

### Production Multi-Tier App

```elixir
defmodule MyApp.Production do
  use CUL8er
  
  topology :production do
    # Database server
    host :db do
      address "10.0.1.10"
      platform :icusos
    end
    
    # Web servers
    host :web_1 do
      address "10.0.1.20"
      platform :icusos
    end
    
    host :web_2 do
      address "10.0.1.21"
      platform :icusos
    end
    
    # PostgreSQL
    resource :postgres, type: :container, on: :db do
      from_image "images:postgres/14"
      limits do
        cpu cores: 4
        memory gigabytes: 8
      end
    end
    
    # Phoenix app - instance 1
    resource :app_1, type: :container, on: :web_1 do
      from_image "images:alpine/3.19"
      
      limits do
        cpu cores: 2
        memory gigabytes: 4
      end
      
      network do
        expose port: 4000, as: 443, protocol: :https
      end
      
      deploy release: :my_app, version: "1.0.0"
    end
    
    # Phoenix app - instance 2
    resource :app_2, type: :container, on: :web_2 do
      # Same config as app_1
    end
    
    # Cluster
    cluster :app_cluster do
      nodes [:app_1, :app_2]
      discovery strategy: Cluster.Strategy.Epmd
      cookie from: :system, key: "RELEASE_COOKIE"
    end
    
    # Deployment strategy
    strategy do
      approach :rolling
      batch_size 1
      
      healthcheck do
        endpoint "http://localhost:4000/health"
        interval seconds: 10
      end
      
      rollback do
        on_failure :automatic
        snapshot true
      end
    end
  end
end

# Deploy
MyApp.Production.deploy(:production)

# Update
MyApp.Production.deploy(:production, version: "1.1.0")

# Check status
MyApp.Production.status(:production)

# View metrics
mix c_u_l8er.metrics production --watch
```

---

## Common Workflows

### First Deployment

```bash
# 1. Define topology
vim lib/my_deployment.ex

# 2. Plan changes
mix c_u_l8er.plan production

# 3. Deploy
mix c_u_l8er.deploy production

# 4. Check status
mix c_u_l8er.status production
```

### Rolling Update

```bash
# 1. Update code and build new release
mix release

# 2. Plan update
mix c_u_l8er.plan production

# 3. Deploy with new version
mix c_u_l8er.deploy production --version 1.1.0

# 4. Watch deployment
mix c_u_l8er.metrics production --watch
```

### Disaster Recovery

```bash
# Rollback to previous version
mix c_u_l8er.rollback production

# Or restore from snapshot
mix c_u_l8er.restore production --snapshot pre-deploy-123456
```

---

## FAQ

**Q: Why not Docker Compose?**  
A: No built-in clustering, no health checking, no deployment strategies, not Elixir-native.

**Q: Why not Kubernetes?**  
A: Too complex for 1-50 node deployments. C U L8er is right-sized for small/medium teams.

**Q: Does it work with Docker?**  
A: No, Incus only. But you can run Incus containers that run Docker if needed.

**Q: Can I use it in production?**  
A: After Phase 5 (v0.1.0), yes for non-critical systems. v1.0.0 will be production-hardened.

**Q: What about Windows/Mac?**  
A: Incus runs on Linux only. Use a Linux VM or remote Linux server.

---

## Getting Help

- **Documentation:** https://hexdocs.pm/c_u_l8er
- **GitHub:** https://github.com/yourusername/c_u_l8er
- **Issues:** https://github.com/yourusername/c_u_l8er/issues
- **Forum:** https://elixirforum.com (tag: c_u_l8er)

---

## Contributing

We welcome contributions! Please see CONTRIBUTING.md for guidelines.

Areas we'd love help with:
- Additional deployment strategies
- More platform support (beyond Arch/icusos)
- Performance optimizations
- Documentation improvements
- Example applications

---

## License

Apache 2.0 - See LICENSE file

---

## Roadmap

**v0.1.0** (End of Phase 5)
- Core DSL and deployment
- Basic strategies
- Clustering
- Observability

**v0.2.0** (Month 4-5)
- Load balancer integration
- Secrets management (Vault)
- Multi-region support
- Web UI (Phoenix LiveView)

**v1.0.0** (Month 6-8)
- Production hardened
- Enterprise features
- Advanced observability
- Plugin system

---

**Start Here:** [PHASE_1_PROMPT.md](PHASE_1_PROMPT.md)

**Next:** Build the DSL layer and get parsing working!
