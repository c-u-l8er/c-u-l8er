# C U L8er Examples

This directory contains example topologies that demonstrate how to use C U L8er for deploying distributed Elixir applications using Incus containers and VMs.

## Available Examples

### Simple Topology (`simple_topology.ex`)

A basic example showing all four DSL layers working together to deploy a single container.

**What it demonstrates:**
- Host definition with platform configuration
- Container resource with image specification
- Resource limits (CPU and memory)
- Network configuration with port exposure
- Environment variables (both plain and secret)
- Rolling deployment strategy
- Health checking configuration
- Automatic rollback on failure

## Quick Start

### 1. Prerequisites

Make sure you have:
- Incus installed and running
- Elixir 1.15+ and OTP 26+
- C U L8er dependencies installed (`mix deps.get`)

### 2. Run the Example

```bash
# Plan the deployment
mix c_u_l8er.plan Examples.SimpleTopology simple

# Deploy (dry run first)
mix c_u_l8er.deploy Examples.SimpleTopology simple --dry-run

# Deploy for real
mix c_u_l8er.deploy Examples.SimpleTopology simple

# Check status
mix c_u_l8er.status simple

# Clean up
mix c_u_l8er.destroy simple
```

### 3. What Happens

When you run the example:

1. **Planning Phase**: C U L8er analyzes the topology and shows what will be created
2. **Deployment Phase**: Creates an Incus container with Alpine Linux
3. **Configuration Phase**: Applies CPU/memory limits, network settings, and environment variables
4. **Health Check Phase**: Verifies the deployment was successful

## Example Breakdown

### Host Definition

```elixir
host :local do
  address("localhost")
  platform(:arch_linux)
end
```

Defines a host where resources will be deployed. For local development, this points to the local Incus instance.

### Resource Definition

```elixir
resource :web, type: :container, on: :local do
  from_image("images:alpine/3.19")
  # ... configuration ...
end
```

Creates a container resource using the Alpine Linux 3.19 image. The `on: :local` specifies which host to deploy to.

### Configuration Layers

#### Limits
```elixir
limits do
  cpu(cores: 2)
  memory(gigabytes: 4)
end
```

Sets CPU and memory limits for the container.

#### Network
```elixir
network do
  expose(port: 4000, as: 443, protocol: :https)
end
```

Exposes port 4000 from the container as port 443 on the host with HTTPS protocol.

#### Environment
```elixir
environment do
  set(:MIX_ENV, "prod")
  secret(:SECRET_KEY_BASE, from: :system)
end
```

Sets environment variables. Plain variables are set directly, while secrets are retrieved from secure storage.

### Strategy Definition

```elixir
strategy do
  approach(:rolling)
  batch_size(1)

  healthcheck do
    endpoint("http://localhost:4000/health")
    interval(seconds: 10)
    retries(3)
  end

  rollback do
    on_failure(:automatic)
    snapshot(true)
  end
end
```

Configures the deployment strategy:
- **Rolling deployment**: Updates resources one at a time
- **Health checks**: Monitors deployment success via HTTP endpoint
- **Automatic rollback**: Reverts changes if deployment fails
- **Snapshots**: Creates backups for rollback

## Advanced Usage

### Remote Deployment

To deploy to a remote host, change the host definition:

```elixir
host :remote do
  address("192.168.1.100")
  platform(:icusos)
  credentials(ssh: [user: "deploy", key: "~/.ssh/deploy_key"])
end

resource :web, type: :container, on: :remote do
  # ... same configuration ...
end
```

### Multiple Resources

Add more resources for a complete application:

```elixir
resource :web, type: :container, on: :remote do
  from_image("images:alpine/3.19")
  # Web app configuration
end

resource :database, type: :container, on: :remote do
  from_image("images:postgres/14")
  # Database configuration
end

cluster :app_cluster do
  nodes([:web])
  discovery(strategy: Cluster.Strategy.Epmd)
end
```

### VM Resources

Deploy full VMs instead of containers:

```elixir
resource :vm_host, type: :vm, on: :remote do
  from_image("images:ubuntu/22.04")
  limits do
    cpu(cores: 4)
    memory(gigabytes: 8)
  end
end
```

## Troubleshooting

### Common Issues

**"Module Examples.SimpleTopology not found"**
- Make sure you're running from the project root
- The examples are compiled automatically in test/dev environments

**"Incus command not found"**
- Install Incus: `sudo snap install incus`
- Initialize Incus: `incus admin init`

**"Permission denied"**
- Add your user to the incus group: `sudo usermod -aG incus $USER`
- Log out and back in for group changes to take effect

**"SSH connection failed"**
- Verify SSH key permissions: `chmod 600 ~/.ssh/deploy_key`
- Test SSH connection manually: `ssh user@host`

### Debug Commands

```bash
# Check Incus status
incus info

# List containers
incus list

# View container logs
incus logs container_name

# Access container shell
incus exec container_name -- /bin/sh
```

## Contributing Examples

To add new examples:

1. Create a new file in `lib/examples/`
2. Follow the naming convention: `*_topology.ex`
3. Use the `Examples` module namespace
4. Update this README with the new example
5. Add appropriate tests in `test/c_u_l8er_integration_test.exs`

## Related Documentation

- **[PROJECT_SPEC.md](../docs/PROJECT_SPEC.md)** - Complete project specification
- **[AI_CODING_PROMPTS.md](../docs/AI_CODING_PROMPTS.md)** - Implementation phases
- **[IMPLEMENTATION_GUIDE.md](../docs/IMPLEMENTATION_GUIDE.md)** - Technical details
- **[HOMELAB_SECURITY_ANALYSIS.md](../docs/HOMELAB_SECURITY_ANALYSIS.md)** - Security considerations

## License

These examples are part of C U L8er and follow the same Apache 2.0 license.