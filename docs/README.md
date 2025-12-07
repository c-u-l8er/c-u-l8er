# C U L8er 
## Computer Units Load-8alancer

**URL:** https://c-u-l8er.link

Elixir-native deployment system for distributed BEAM applications using Incus containers and VMs.

## Quick Start

```elixir
# Define your infrastructure
defmodule MyApp.Infrastructure do
  use CUL8er
  
  topology :production do
    host :web_server do
      address "prod.example.com"
      platform :icusos
    end
    
    resource :web, type: :container, on: :web_server do
      from_image "images:alpine/3.19"
      
      limits do
        cpu cores: 4
        memory gigabytes: 8
      end
      
      network do
        expose port: 4000, as: 443
      end
    end
    
    strategy do
      approach :rolling
      healthcheck do
        endpoint "http://localhost:4000/health"
      end
    end
  end
end

# Deploy
mix c_u_l8er.deploy production
```

## Features

- **Clean DSL:** Four semantic layers (Infrastructure/Configuration/Strategy/Cluster)
- **Zero Downtime:** Rolling, blue-green, and canary deployments
- **BEAM-First:** Automatic Elixir clustering with libcluster
- **Observable:** Built-in health checks and telemetry
- **Incus-Powered:** Containers and VMs on local or remote hosts

## Installation

```elixir
def deps do
  [
    {:c_u_l8er, "~> 0.1.0"}
  ]
end
```

## Architecture

```
┌─────────────────────────────────────┐
│         DSL Layer                   │
│  (Infrastructure/Config/Strategy)   │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│       Core Execution                │
│  (Executor → Incus/SSH → State)     │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│    Deployment Strategies            │
│  (Rolling/BlueGreen/Canary)         │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│    Clustering & Observable          │
│  (libcluster + Telemetry)           │
└─────────────────────────────────────┘
```

## Documentation

- **[PROJECT_SPEC.md](PROJECT_SPEC.md)** - Complete project specification
- **[AI_CODING_PROMPTS.md](AI_CODING_PROMPTS.md)** - Phase-by-phase implementation guide
- **[IMPLEMENTATION_GUIDE.md](IMPLEMENTATION_GUIDE.md)** - Technical details

## Implementation Status

**Current:** Design specification complete  
**Next:** Phase 1 - DSL Foundation (Weeks 1-2)

See [AI_CODING_PROMPTS.md](AI_CODING_PROMPTS.md) for complete implementation roadmap.

## Why C U L8er?

### vs. Docker Compose
✅ Built-in clustering  
✅ VM support  
✅ Production-grade strategies  

### vs. Kubernetes
✅ 10x simpler  
✅ Perfect for 1-50 nodes  
✅ No YAML hell  

### vs. Terraform
✅ Application-focused  
✅ Elixir-native  
✅ Built-in health checks  

## License

Apache 2.0

## Contributing

This project is currently in design phase. Implementation contributions welcome!

See [AI_CODING_PROMPTS.md](AI_CODING_PROMPTS.md) to get started.
