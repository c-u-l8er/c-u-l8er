# C U L8er - Computer Units Load-8alancer

**Project Name:** C U L8er (pronounced "See You Later")  
**URL:** https://c-u-l8er.link  
**Purpose:** Elixir-native deployment system for distributed BEAM applications using Incus

## Project Vision

A single, clean DSL for deploying distributed Elixir applications with:
- **Semantic layer separation** (Infrastructure/Config/Strategy/Cluster)
- **Incus-powered** container and VM management
- **BEAM-native** clustering with libcluster
- **Built-in observability** for deployment health

## Architecture Principles

1. **One DSL, Done Right** - No backwards compatibility, clean design from scratch
2. **Semantic Layers** - Clear separation: WHAT/HOW/WHEN/COMMUNICATION
3. **Elixir-First** - Built for BEAM, distributed systems as first-class concern
4. **Observable** - Metrics, health, and status built-in from day one

## Core DSL Design

```elixir
use CUL8er

topology :production do
  # Infrastructure Layer - WHAT exists
  host :remote do
    address "prod.example.com"
    platform :icusos
    credentials ssh: [user: "deploy", key: "~/.ssh/id_rsa"]
  end
  
  # Resources
  resource :web, type: :container, on: :remote do
    from_image "images:alpine/3.19"
    
    # Configuration Layer - HOW it's configured
    limits do
      cpu cores: 4
      memory gigabytes: 4
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
  
  # Cluster Layer - HOW nodes communicate
  cluster :app_cluster do
    nodes [:web]
    discovery strategy: Cluster.Strategy.Epmd
    cookie from: :system, key: "RELEASE_COOKIE"
  end
  
  # Strategy Layer - WHEN/HOW to deploy
  strategy do
    approach :rolling
    
    healthcheck do
      interval seconds: 10
      timeout seconds: 5
      retries 3
      endpoint "http://localhost:4000/health"
    end
    
    rollback do
      on_failure :automatic
      keep_versions 3
      snapshot true
    end
  end
end
```

## Module Structure

```
c_u_l8er/
├── lib/
│   ├── c_u_l8er.ex                    # Main DSL entry point
│   ├── c_u_l8er/
│   │   ├── dsl/
│   │   │   ├── infrastructure.ex     # WHAT: hosts, resources
│   │   │   ├── configuration.ex      # HOW: limits, network, storage
│   │   │   ├── strategy.ex           # WHEN: deployment approach
│   │   │   └── cluster.ex            # COMMUNICATION: node discovery
│   │   ├── core/
│   │   │   ├── incus.ex              # Incus CLI integration
│   │   │   ├── ssh.ex                # SSH operations
│   │   │   ├── state.ex              # State management
│   │   │   └── executor.ex           # Deployment execution
│   │   ├── cluster/
│   │   │   ├── manager.ex            # Cluster formation
│   │   │   └── topology.ex           # libcluster integration
│   │   ├── strategies/
│   │   │   ├── rolling.ex            # Rolling deployment
│   │   │   ├── blue_green.ex         # Blue-green deployment
│   │   │   └── canary.ex             # Canary deployment
│   │   └── observable/
│   │       ├── metrics.ex            # Telemetry integration
│   │       └── health.ex             # Health checking
│   └── mix/
│       └── tasks/
│           ├── c_u_l8er.deploy.ex     # Deploy command
│           ├── c_u_l8er.plan.ex       # Plan changes
│           └── c_u_l8er.status.ex     # Check status
├── test/
└── priv/
    └── schemas/
        └── state_v1.json             # State schema
```

## Implementation Phases

**Phase 1:** Core DSL & Infrastructure (Weeks 1-2)  
**Phase 2:** Incus Integration & State (Weeks 3-4)  
**Phase 2.5:** Security Hardening (Week 5)  
**Phase 3:** Deployment Strategies (Weeks 6-7)  
**Phase 4:** Clustering & Observability (Weeks 8-9)  
**Phase 5:** Testing & Polish (Weeks 10-11)

## Technology Stack

- **Language:** Elixir 1.15+, OTP 26+
- **Container/VM:** Incus (LXD fork)
- **Clustering:** libcluster
- **State:** PostgreSQL or JSON files
- **Telemetry:** telemetry + telemetry_metrics
- **Testing:** ExUnit + Mox

## Target Platforms

- **Local Development:** Arch Linux with Incus
- **Remote Production:** icusos servers with Incus
- **Future:** Any Linux with Incus support

## Success Metrics

- ✅ Deploy Phoenix app in <30 seconds
- ✅ Form 3-node cluster automatically
- ✅ Zero-downtime rolling updates
- ✅ Automatic rollback on failure
- ✅ Real-time health monitoring

## Differentiation

**vs. Docker Compose:** Built-in clustering, VM support, Elixir-native
**vs. Kubernetes:** 10x simpler, perfect for 1-50 node deployments
**vs. Terraform:** Application-focused, not infrastructure-focused
**vs. Ansible:** Declarative, type-safe, built for BEAM

## License

Apache 2.0
