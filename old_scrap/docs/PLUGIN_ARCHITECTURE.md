# C U L8er - Plugin Architecture & Multi-Tenant SaaS Design

**Project:** C U L8er (Computer Units Load-8alancer)  
**URL:** https://c-u-l8er.link  
**Document Version:** 1.0  
**Phase:** 6 (Post-MVP Enhancement)

---

## Executive Summary

This document defines the **plugin architecture** for C U L8er, enabling:

1. **Deployment Extensions** - Custom strategies, platforms, observers
2. **Multi-Tenant SaaS** - Automatic resource provisioning based on subscription plans
3. **Third-Party Integrations** - Monitoring, secrets, load balancers
4. **Custom DSL Extensions** - Domain-specific deployment patterns

### Key Design Goals

- ✅ **Zero-config plugin discovery** - Plugins auto-register on load
- ✅ **Type-safe plugin contracts** - Behaviours ensure correctness
- ✅ **Composable plugins** - Chain multiple plugins together
- ✅ **Tenant isolation** - Resources strictly separated by tenant
- ✅ **Usage metering** - Track resource consumption per tenant
- ✅ **Subscription-driven** - Auto-scale resources based on plan

---

## Table of Contents

1. [Plugin Types](#plugin-types)
2. [Core Architecture](#core-architecture)
3. [Plugin Lifecycle](#plugin-lifecycle)
4. [Plugin Behaviours](#plugin-behaviours)
5. [Multi-Tenant SaaS Implementation](#multi-tenant-saas-implementation)
6. [Security Model](#security-model)
7. [Plugin Discovery & Loading](#plugin-discovery--loading)
8. [Example Plugins](#example-plugins)
9. [Implementation Guide](#implementation-guide)
10. [Testing Strategies](#testing-strategies)

---

## Plugin Types

### 1. Deployment Strategy Plugins

Extend deployment approaches beyond rolling/blue-green/canary.

**Examples:**
- Progressive delivery (feature flags)
- Shadow deployments (dark launching)
- Chaos engineering (controlled failures)
- Geographic rollout (region-by-region)

**Interface:**
```elixir
@callback deploy(topology, resources, opts) :: {:ok, result} | {:error, reason}
@callback rollback(topology, resources, opts) :: {:ok, result} | {:error, reason}
@callback health_check(topology, resources) :: :healthy | :degraded | :unhealthy
```

### 2. Platform Plugins

Support new container/VM platforms beyond Incus.

**Examples:**
- Docker/Podman
- Firecracker
- QEMU/KVM
- Cloud providers (AWS ECS, GCP Cloud Run)

**Interface:**
```elixir
@callback create_instance(host, resource, config) :: {:ok, instance} | {:error, reason}
@callback destroy_instance(host, instance_id) :: :ok | {:error, reason}
@callback exec(host, instance_id, command) :: {:ok, output} | {:error, reason}
```

### 3. Observer Plugins

Add monitoring, metrics, and alerting integrations.

**Examples:**
- Prometheus exporter
- Datadog integration
- Custom webhooks
- Slack notifications

**Interface:**
```elixir
@callback observe_event(event_type, metadata) :: :ok
@callback report_metric(metric_name, value, tags) :: :ok
@callback health_status(topology) :: map()
```

### 4. Tenant Provisioner Plugins

**NEW** - Auto-provision resources for SaaS tenants.

**Examples:**
- Database per tenant
- Container per tenant
- Shared cluster with namespacing
- Multi-region tenant placement

**Interface:**
```elixir
@callback provision_tenant(tenant_id, subscription_plan) :: {:ok, resources} | {:error, reason}
@callback deprovision_tenant(tenant_id) :: :ok | {:error, reason}
@callback scale_tenant(tenant_id, new_plan) :: {:ok, resources} | {:error, reason}
@callback meter_usage(tenant_id) :: {:ok, usage_map} | {:error, reason}
```

### 5. Secrets Provider Plugins

Integrate with external secret management systems.

**Examples:**
- HashiCorp Vault
- AWS Secrets Manager
- Azure Key Vault
- 1Password Connect

**Interface:**
```elixir
@callback retrieve_secret(path) :: {:ok, value} | {:error, reason}
@callback store_secret(path, value) :: :ok | {:error, reason}
@callback rotate_secret(path) :: {:ok, new_value} | {:error, reason}
```

### 6. Load Balancer Plugins

Integrate with load balancers for traffic management.

**Examples:**
- HAProxy
- Nginx
- Traefik
- Caddy
- Cloud load balancers (AWS ALB, GCP LB)

**Interface:**
```elixir
@callback add_backend(lb_name, backend_url, opts) :: :ok | {:error, reason}
@callback remove_backend(lb_name, backend_url) :: :ok | {:error, reason}
@callback health_check(lb_name) :: {:ok, status} | {:error, reason}
```

---

## Core Architecture

### Plugin System Components

```
┌─────────────────────────────────────────────────────────┐
│                   Plugin Registry                        │
│  - Discover plugins at compile/runtime                  │
│  - Validate plugin contracts (behaviours)               │
│  - Manage plugin lifecycle                              │
└─────────────────┬───────────────────────────────────────┘
                  │
      ┌───────────┼───────────┬───────────────┐
      │           │           │               │
  ┌───▼───┐   ┌───▼───┐   ┌───▼────┐   ┌─────▼──────┐
  │Strategy│   │Platform│   │Observer│   │  Tenant    │
  │ Plugins│   │ Plugins│   │ Plugins│   │Provisioner │
  └────────┘   └────────┘   └────────┘   └────────────┘
      │           │           │               │
      └───────────┴───────────┴───────────────┘
                  │
      ┌───────────▼───────────────────────────────────┐
      │         Plugin Execution Pipeline             │
      │  - Before/After hooks                         │
      │  - Plugin composition                         │
      │  - Error handling                             │
      └───────────────────────────────────────────────┘
```

### File Structure

```
c_u_l8er/
├── lib/
│   ├── c_u_l8er/
│   │   ├── plugin/
│   │   │   ├── registry.ex              # Plugin discovery & loading
│   │   │   ├── behaviour.ex             # Base plugin behaviour
│   │   │   ├── lifecycle.ex             # Plugin lifecycle management
│   │   │   ├── pipeline.ex              # Execution pipeline
│   │   │   └── behaviours/
│   │   │       ├── strategy.ex          # Strategy plugin behaviour
│   │   │       ├── platform.ex          # Platform plugin behaviour
│   │   │       ├── observer.ex          # Observer plugin behaviour
│   │   │       ├── tenant_provisioner.ex # Tenant plugin behaviour
│   │   │       ├── secrets.ex           # Secrets plugin behaviour
│   │   │       └── load_balancer.ex     # LB plugin behaviour
│   │   │
│   │   ├── plugins/                     # Built-in plugins
│   │   │   ├── strategies/
│   │   │   │   ├── rolling.ex
│   │   │   │   ├── blue_green.ex
│   │   │   │   └── canary.ex
│   │   │   ├── platforms/
│   │   │   │   ├── incus.ex
│   │   │   │   └── docker.ex (optional)
│   │   │   ├── observers/
│   │   │   │   ├── telemetry.ex
│   │   │   │   └── prometheus.ex
│   │   │   └── tenant_provisioners/
│   │   │       ├── database_per_tenant.ex
│   │   │       ├── container_per_tenant.ex
│   │   │       └── shared_cluster.ex
│   │   │
│   │   └── saas/                        # SaaS-specific modules
│   │       ├── tenant.ex                # Tenant management
│   │       ├── subscription.ex          # Subscription plans
│   │       ├── metering.ex              # Usage tracking
│   │       ├── billing.ex               # Billing integration
│   │       └── isolation.ex             # Tenant isolation
│   │
│   └── mix/tasks/
│       └── c_u_l8er.plugin.ex           # Plugin management CLI
│
├── priv/
│   └── plugins/                         # User plugins directory
│
└── examples/
    └── plugins/
        ├── custom_strategy.ex
        ├── datadog_observer.ex
        └── tenant_provisioner.ex
```

---

## Plugin Lifecycle

### 1. Discovery Phase

**Compile-time discovery:**
```elixir
# In mix.exs
defp plugins do
  [
    # Load from deps
    {:c_u_l8er_datadog, "~> 1.0"},
    {:c_u_l8er_prometheus, "~> 1.0"},
    
    # Load from local path
    {:path, "priv/plugins/custom_strategy"}
  ]
end
```

**Runtime discovery:**
```elixir
# Scan priv/plugins/ directory
CUL8er.Plugin.Registry.discover_plugins()
```

### 2. Registration Phase

Plugins register themselves using module attributes:

```elixir
defmodule MyApp.CustomStrategy do
  use CUL8er.Plugin.Strategy
  
  @plugin_name :progressive_delivery
  @plugin_version "1.0.0"
  @plugin_description "Deploy with feature flags"
  
  # Plugin implementation...
end
```

### 3. Validation Phase

Registry validates plugin contracts:
- Implements required callbacks
- Has valid metadata
- No naming conflicts
- Dependencies satisfied

### 4. Initialization Phase

Plugins initialize resources:
```elixir
@callback init(opts) :: {:ok, state} | {:error, reason}
```

### 5. Execution Phase

Plugins execute during deployment:
```elixir
CUL8er.Plugin.Pipeline.execute(:strategy, :deploy, [topology, resources])
```

### 6. Cleanup Phase

Plugins cleanup on termination:
```elixir
@callback terminate(state) :: :ok
```

---

## Plugin Behaviours

### Strategy Plugin Behaviour

```elixir
defmodule CUL8er.Plugin.Behaviour.Strategy do
  @moduledoc """
  Behaviour for deployment strategy plugins.
  """
  
  @callback deploy(topology :: map(), resources :: [map()], opts :: keyword()) ::
              {:ok, result :: map()} | {:error, reason :: term()}
  
  @callback rollback(topology :: map(), resources :: [map()], opts :: keyword()) ::
              {:ok, result :: map()} | {:error, reason :: term()}
  
  @callback health_check(topology :: map(), resources :: [map()]) ::
              :healthy | :degraded | :unhealthy
  
  @callback estimate_duration(resources :: [map()]) :: pos_integer()
  
  @optional_callbacks [estimate_duration: 1]
end

defmodule CUL8er.Plugin.Strategy do
  @moduledoc """
  Macro for creating strategy plugins.
  """
  
  defmacro __using__(_opts) do
    quote do
      @behaviour CUL8er.Plugin.Behaviour.Strategy
      
      def init(opts), do: {:ok, opts}
      def terminate(_state), do: :ok
      
      defoverridable init: 1, terminate: 1
    end
  end
end
```

### Tenant Provisioner Behaviour

```elixir
defmodule CUL8er.Plugin.Behaviour.TenantProvisioner do
  @moduledoc """
  Behaviour for tenant provisioning plugins.
  
  Handles automatic resource provisioning based on subscription plans.
  """
  
  @type tenant_id :: String.t()
  @type subscription_plan :: atom() | String.t()
  @type resources :: map()
  @type usage_map :: %{
    cpu: number(),
    memory: number(),
    storage: number(),
    requests: number(),
    custom: map()
  }
  
  @doc """
  Provision resources for a new tenant.
  """
  @callback provision_tenant(tenant_id(), subscription_plan(), opts :: keyword()) ::
              {:ok, resources()} | {:error, reason :: term()}
  
  @doc """
  Deprovision all resources for a tenant.
  """
  @callback deprovision_tenant(tenant_id()) ::
              :ok | {:error, reason :: term()}
  
  @doc """
  Scale tenant resources to match new subscription plan.
  """
  @callback scale_tenant(tenant_id(), subscription_plan()) ::
              {:ok, resources()} | {:error, reason :: term()}
  
  @doc """
  Meter resource usage for billing.
  """
  @callback meter_usage(tenant_id()) ::
              {:ok, usage_map()} | {:error, reason :: term()}
  
  @doc """
  Check tenant health and isolation.
  """
  @callback health_check(tenant_id()) ::
              {:ok, :healthy | :degraded | :unhealthy} | {:error, reason :: term()}
  
  @doc """
  Get current resource allocation for tenant.
  """
  @callback get_resources(tenant_id()) ::
              {:ok, resources()} | {:error, reason :: term()}
end

defmodule CUL8er.Plugin.TenantProvisioner do
  @moduledoc """
  Macro for creating tenant provisioner plugins.
  """
  
  defmacro __using__(_opts) do
    quote do
      @behaviour CUL8er.Plugin.Behaviour.TenantProvisioner
      
      def init(opts), do: {:ok, opts}
      def terminate(_state), do: :ok
      
      defoverridable init: 1, terminate: 1
    end
  end
end
```

### Observer Plugin Behaviour

```elixir
defmodule CUL8er.Plugin.Behaviour.Observer do
  @moduledoc """
  Behaviour for monitoring and observability plugins.
  """
  
  @type event_type :: atom()
  @type metadata :: map()
  @type metric_name :: String.t()
  @type metric_value :: number()
  @type tags :: keyword()
  
  @callback observe_event(event_type(), metadata()) :: :ok
  
  @callback report_metric(metric_name(), metric_value(), tags()) :: :ok
  
  @callback health_status(topology :: map()) :: map()
  
  @callback flush() :: :ok
  
  @optional_callbacks [flush: 0]
end
```

---

## Multi-Tenant SaaS Implementation

### Tenant Model

```elixir
defmodule CUL8er.SaaS.Tenant do
  @moduledoc """
  Tenant data structure and management.
  """
  
  defstruct [
    :id,
    :name,
    :subscription_plan,
    :resources,
    :status,
    :metadata,
    :created_at,
    :updated_at
  ]
  
  @type t :: %__MODULE__{
    id: String.t(),
    name: String.t(),
    subscription_plan: subscription_plan(),
    resources: map(),
    status: :active | :suspended | :terminated,
    metadata: map(),
    created_at: DateTime.t(),
    updated_at: DateTime.t()
  }
  
  @type subscription_plan :: :free | :starter | :pro | :enterprise
end
```

### Subscription Plans

```elixir
defmodule CUL8er.SaaS.Subscription do
  @moduledoc """
  Define subscription plans and resource limits.
  """
  
  @plans %{
    free: %{
      cpu_cores: 0.5,
      memory_gb: 0.5,
      storage_gb: 1,
      max_instances: 1,
      max_requests_per_month: 10_000,
      support: :community
    },
    starter: %{
      cpu_cores: 2,
      memory_gb: 4,
      storage_gb: 20,
      max_instances: 3,
      max_requests_per_month: 100_000,
      support: :email
    },
    pro: %{
      cpu_cores: 8,
      memory_gb: 16,
      storage_gb: 100,
      max_instances: 10,
      max_requests_per_month: 1_000_000,
      support: :priority
    },
    enterprise: %{
      cpu_cores: :unlimited,
      memory_gb: :unlimited,
      storage_gb: :unlimited,
      max_instances: :unlimited,
      max_requests_per_month: :unlimited,
      support: :dedicated
    }
  }
  
  def get_plan(plan_name) do
    Map.get(@plans, plan_name)
  end
  
  def all_plans, do: @plans
end
```

### SaaS Topology DSL

```elixir
defmodule MyApp.SaaSTenants do
  use CUL8er
  
  # Define multi-tenant topology
  topology :saas_platform do
    # Shared infrastructure
    host :app_cluster do
      address "cluster.example.com"
      platform :incusos
    end
    
    # Tenant provisioning configuration
    tenants do
      provisioner :container_per_tenant do
        plugin MyApp.Plugins.ContainerPerTenant
        
        isolation :strict  # Network + storage isolation
        
        # Resource quotas per plan
        plans do
          free do
            cpu cores: 0.5
            memory gigabytes: 0.5
            storage gigabytes: 1
          end
          
          starter do
            cpu cores: 2
            memory gigabytes: 4
            storage gigabytes: 20
          end
          
          pro do
            cpu cores: 8
            memory gigabytes: 16
            storage gigabytes: 100
          end
        end
        
        # Auto-scaling rules
        autoscale do
          metric :cpu_usage
          threshold 80  # percent
          action :upgrade_plan
          cooldown minutes: 15
        end
      end
      
      # Metering configuration
      metering do
        track [:cpu, :memory, :storage, :requests, :bandwidth]
        interval seconds: 60
        aggregation :sum
        
        billing_cycle :monthly
        
        # Send metrics to billing system
        reporter :stripe do
          api_key from: :secret_store, key: "stripe/api_key"
          webhook_secret from: :secret_store, key: "stripe/webhook_secret"
        end
      end
      
      # Security & isolation
      security do
        tenant_isolation :strict
        
        network do
          # Each tenant gets isolated network
          per_tenant_subnet true
          subnet_cidr "10.100.0.0/16"
        end
        
        storage do
          # Encrypted volumes per tenant
          encryption :aes_256
          per_tenant_volume true
        end
      end
    end
    
    # Shared services (database, cache, etc.)
    resource :shared_postgres, type: :container, on: :app_cluster do
      from_image "images:postgres/14"
      
      limits do
        cpu cores: 16
        memory gigabytes: 64
      end
      
      storage do
        volume :data, mount: "/var/lib/postgresql/data", size_gb: 500
      end
    end
    
    resource :shared_redis, type: :container, on: :app_cluster do
      from_image "images:redis/7"
      
      limits do
        cpu cores: 4
        memory gigabytes: 16
      end
    end
    
    # Monitoring
    observability do
      metrics [:tenant_count, :resource_usage, :billing_events]
      
      observers [
        MyApp.Plugins.PrometheusObserver,
        MyApp.Plugins.DatadogObserver
      ]
    end
  end
end
```

### Tenant Lifecycle

```elixir
# Create new tenant
{:ok, tenant} = CUL8er.SaaS.Tenant.create(%{
  name: "Acme Corp",
  subscription_plan: :starter
})

# Auto-provisions resources based on plan
CUL8er.SaaS.provision_tenant(tenant.id)

# Scale tenant to new plan
CUL8er.SaaS.upgrade_tenant(tenant.id, :pro)

# Meter usage (runs automatically via cron)
{:ok, usage} = CUL8er.SaaS.meter_tenant(tenant.id)
# => %{cpu: 1.8, memory: 3.2, storage: 15, requests: 45_000}

# Suspend tenant (non-payment)
CUL8er.SaaS.suspend_tenant(tenant.id)

# Terminate tenant
CUL8er.SaaS.deprovision_tenant(tenant.id)
```

---

## Security Model

### Plugin Sandboxing

Plugins run with restricted permissions:

```elixir
defmodule CUL8er.Plugin.Sandbox do
  @moduledoc """
  Isolate plugin execution.
  """
  
  def execute(plugin_module, function, args, opts \\ []) do
    timeout = Keyword.get(opts, :timeout, 30_000)
    
    task = Task.async(fn ->
      # Limit resources
      Process.flag(:max_heap_size, 100_000_000)  # 100MB
      
      # Execute plugin
      apply(plugin_module, function, args)
    end)
    
    case Task.yield(task, timeout) || Task.shutdown(task) do
      {:ok, result} -> result
      nil -> {:error, :timeout}
    end
  end
end
```

### Tenant Isolation

**Network Isolation:**
```elixir
# Each tenant gets own subnet
tenant_subnet = CUL8er.SaaS.Isolation.allocate_subnet(tenant_id)
# => "10.100.42.0/24"

# Firewall rules prevent cross-tenant traffic
CUL8er.SaaS.Isolation.configure_firewall(tenant_id, [
  allow_from: :internet,
  deny_from: :other_tenants
])
```

**Storage Isolation:**
```elixir
# Encrypted volumes per tenant
CUL8er.SaaS.Isolation.create_volume(tenant_id, %{
  size_gb: 20,
  encryption: :aes_256,
  key_source: :per_tenant
})
```

**Compute Isolation:**
```elixir
# Dedicated resources or cgroups
CUL8er.SaaS.Isolation.allocate_resources(tenant_id, %{
  cpu_quota: 200_000,  # 2 cores
  memory_limit: 4_294_967_296  # 4GB
})
```

### Plugin Permissions

```elixir
defmodule CUL8er.Plugin.Permissions do
  @moduledoc """
  Define what plugins can access.
  """
  
  @permissions %{
    # Strategy plugins
    strategy: [
      :read_topology,
      :write_state,
      :execute_deployment,
      :read_metrics
    ],
    
    # Tenant provisioner plugins
    tenant_provisioner: [
      :create_resources,
      :delete_resources,
      :read_tenant_data,
      :write_tenant_data,
      :read_billing,
      :write_metrics
    ],
    
    # Observer plugins (read-only)
    observer: [
      :read_metrics,
      :read_events,
      :write_external  # Can send to external systems
    ]
  }
  
  def check_permission(plugin_type, permission) do
    @permissions
    |> Map.get(plugin_type, [])
    |> Enum.member?(permission)
  end
end
```

---

## Plugin Discovery & Loading

### Registry Implementation

```elixir
defmodule CUL8er.Plugin.Registry do
  use GenServer
  
  @moduledoc """
  Discover, validate, and manage plugins.
  """
  
  defstruct plugins: %{}, metadata: %{}
  
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end
  
  def register(plugin_module, type, metadata) do
    GenServer.call(__MODULE__, {:register, plugin_module, type, metadata})
  end
  
  def get_plugin(type, name) do
    GenServer.call(__MODULE__, {:get_plugin, type, name})
  end
  
  def list_plugins(type) do
    GenServer.call(__MODULE__, {:list_plugins, type})
  end
  
  # Implementation
  def init(_opts) do
    # Auto-discover plugins
    plugins = discover_plugins()
    
    {:ok, %__MODULE__{plugins: plugins}}
  end
  
  def handle_call({:register, plugin_module, type, metadata}, _from, state) do
    # Validate plugin
    case validate_plugin(plugin_module, type) do
      :ok ->
        new_plugins = put_in(
          state.plugins,
          [type, metadata.name],
          {plugin_module, metadata}
        )
        
        {:reply, :ok, %{state | plugins: new_plugins}}
      
      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end
  
  defp discover_plugins do
    # Scan for modules implementing plugin behaviours
    :code.all_loaded()
    |> Enum.filter(fn {module, _} ->
      is_plugin?(module)
    end)
    |> Enum.reduce(%{}, fn {module, _}, acc ->
      type = get_plugin_type(module)
      metadata = get_plugin_metadata(module)
      
      put_in(acc, [type, metadata.name], {module, metadata})
    end)
  end
  
  defp is_plugin?(module) do
    behaviours = module.module_info(:attributes)[:behaviour] || []
    
    Enum.any?(behaviours, fn behaviour ->
      String.starts_with?(to_string(behaviour), "Elixir.CUL8er.Plugin.Behaviour")
    end)
  end
  
  defp validate_plugin(module, type) do
    behaviour = get_behaviour_module(type)
    
    # Check if module implements all required callbacks
    required_callbacks = behaviour.behaviour_info(:callbacks)
    implemented_callbacks = module.module_info(:exports)
    
    missing = required_callbacks -- implemented_callbacks
    
    if missing == [] do
      :ok
    else
      {:error, {:missing_callbacks, missing}}
    end
  end
end
```

### Plugin Auto-Registration

```elixir
defmodule CUL8er.Plugin.Strategy do
  defmacro __using__(_opts) do
    quote do
      @behaviour CUL8er.Plugin.Behaviour.Strategy
      
      @before_compile CUL8er.Plugin.Strategy
      
      # Defaults
      def init(opts), do: {:ok, opts}
      def terminate(_state), do: :ok
      
      defoverridable init: 1, terminate: 1
    end
  end
  
  defmacro __before_compile__(env) do
    # Extract plugin metadata from module attributes
    name = Module.get_attribute(env.module, :plugin_name) || 
           env.module |> Module.split() |> List.last() |> Macro.underscore() |> String.to_atom()
    
    version = Module.get_attribute(env.module, :plugin_version) || "0.1.0"
    description = Module.get_attribute(env.module, :plugin_description) || ""
    
    quote do
      def __plugin_metadata__ do
        %{
          name: unquote(name),
          version: unquote(version),
          description: unquote(description),
          type: :strategy
        }
      end
      
      # Auto-register on load
      def __on_load__ do
        CUL8er.Plugin.Registry.register(
          __MODULE__,
          :strategy,
          __plugin_metadata__()
        )
      end
    end
  end
end
```

---

## Example Plugins

### Example 1: Progressive Delivery Strategy

```elixir
defmodule MyApp.Plugins.ProgressiveDelivery do
  use CUL8er.Plugin.Strategy
  
  @plugin_name :progressive_delivery
  @plugin_version "1.0.0"
  @plugin_description "Deploy with feature flags and gradual rollout"
  
  @impl true
  def deploy(topology, resources, opts) do
    # 1. Deploy new version with feature flag disabled
    {:ok, new_instances} = deploy_with_flag_off(resources)
    
    # 2. Gradually enable feature flag
    percentages = [10, 25, 50, 75, 100]
    
    Enum.reduce_while(percentages, :ok, fn percentage, _acc ->
      # Enable flag for percentage of users
      enable_feature_flag(percentage)
      
      # Monitor metrics
      :timer.sleep(opts[:monitor_duration] || 60_000)
      
      case check_metrics(topology, percentage) do
        :healthy -> {:cont, :ok}
        :degraded -> {:halt, {:error, :rollback_needed}}
      end
    end)
    
    {:ok, %{strategy: :progressive_delivery, instances: new_instances}}
  end
  
  @impl true
  def rollback(topology, resources, opts) do
    # Disable feature flag immediately
    disable_feature_flag()
    
    # Remove new instances
    remove_instances(resources)
    
    {:ok, %{rolled_back: true}}
  end
  
  @impl true
  def health_check(topology, resources) do
    # Check error rates, latency, etc.
    metrics = get_metrics(topology)
    
    cond do
      metrics.error_rate > 0.05 -> :unhealthy
      metrics.p99_latency > 1000 -> :degraded
      true -> :healthy
    end
  end
  
  defp enable_feature_flag(percentage) do
    # Call feature flag service
    HTTPoison.post(
      "https://featureflags.example.com/api/enable",
      Jason.encode!(%{flag: "new_version", percentage: percentage})
    )
  end
end
```

### Example 2: Container Per Tenant Provisioner

```elixir
defmodule MyApp.Plugins.ContainerPerTenant do
  use CUL8er.Plugin.TenantProvisioner
  
  @plugin_name :container_per_tenant
  @plugin_version "1.0.0"
  @plugin_description "Provision dedicated container for each tenant"
  
  @impl true
  def provision_tenant(tenant_id, subscription_plan, opts) do
    # Get resource limits for plan
    limits = CUL8er.SaaS.Subscription.get_plan(subscription_plan)
    
    # Allocate network subnet
    {:ok, subnet} = CUL8er.SaaS.Isolation.allocate_subnet(tenant_id)
    
    # Create container
    {:ok, container} = CUL8er.Core.Incus.create_instance(
      "localhost",
      %{
        name: "tenant-#{tenant_id}",
        type: :container,
        image: "images:alpine/3.19",
        limits: %{
          cpu_cores: limits.cpu_cores,
          memory_gb: limits.memory_gb
        },
        network: %{
          subnet: subnet,
          isolated: true
        }
      }
    )
    
    # Create database
    {:ok, database} = create_tenant_database(tenant_id)
    
    # Store tenant resources
    resources = %{
      container: container,
      database: database,
      subnet: subnet
    }
    
    CUL8er.SaaS.Tenant.update_resources(tenant_id, resources)
    
    {:ok, resources}
  end
  
  @impl true
  def deprovision_tenant(tenant_id) do
    # Get tenant resources
    {:ok, tenant} = CUL8er.SaaS.Tenant.get(tenant_id)
    
    # Delete container
    CUL8er.Core.Incus.delete_instance("localhost", tenant.resources.container.name)
    
    # Delete database
    delete_tenant_database(tenant_id)
    
    # Release subnet
    CUL8er.SaaS.Isolation.release_subnet(tenant.resources.subnet)
    
    :ok
  end
  
  @impl true
  def scale_tenant(tenant_id, new_plan) do
    {:ok, tenant} = CUL8er.SaaS.Tenant.get(tenant_id)
    new_limits = CUL8er.SaaS.Subscription.get_plan(new_plan)
    
    # Update container limits
    CUL8er.Core.Incus.set_limits(
      "localhost",
      tenant.resources.container.name,
      %{
        cpu_cores: new_limits.cpu_cores,
        memory_gb: new_limits.memory_gb
      }
    )
    
    # Update storage if needed
    if new_limits.storage_gb > tenant.resources.storage_gb do
      resize_volume(tenant_id, new_limits.storage_gb)
    end
    
    {:ok, tenant.resources}
  end
  
  @impl true
  def meter_usage(tenant_id) do
    {:ok, tenant} = CUL8er.SaaS.Tenant.get(tenant_id)
    
    # Get container stats
    {:ok, stats} = CUL8er.Core.Incus.stats(
      "localhost",
      tenant.resources.container.name
    )
    
    # Get request count from logs
    {:ok, requests} = count_requests(tenant_id)
    
    usage = %{
      cpu: stats.cpu_seconds,
      memory: stats.memory_bytes,
      storage: stats.disk_bytes,
      requests: requests,
      bandwidth: stats.network_bytes
    }
    
    # Store for billing
    CUL8er.SaaS.Metering.record(tenant_id, usage)
    
    {:ok, usage}
  end
  
  @impl true
  def health_check(tenant_id) do
    {:ok, tenant} = CUL8er.SaaS.Tenant.get(tenant_id)
    
    # Check container health
    case CUL8er.Core.Incus.exec(
      "localhost",
      tenant.resources.container.name,
      "curl -f http://localhost:4000/health"
    ) do
      {:ok, _} -> {:ok, :healthy}
      {:error, _} -> {:ok, :unhealthy}
    end
  end
  
  @impl true
  def get_resources(tenant_id) do
    case CUL8er.SaaS.Tenant.get(tenant_id) do
      {:ok, tenant} -> {:ok, tenant.resources}
      error -> error
    end
  end
  
  # Private helpers
  defp create_tenant_database(tenant_id) do
    # Create PostgreSQL database for tenant
    # In production, use connection pooling
  end
  
  defp delete_tenant_database(tenant_id) do
    # Drop database
  end
  
  defp resize_volume(tenant_id, new_size_gb) do
    # Resize storage volume
  end
  
  defp count_requests(tenant_id) do
    # Query logs or metrics for request count
    {:ok, 45_000}
  end
end
```

### Example 3: Prometheus Observer

```elixir
defmodule MyApp.Plugins.PrometheusObserver do
  use CUL8er.Plugin.Observer
  
  @plugin_name :prometheus
  @plugin_version "1.0.0"
  @plugin_description "Export metrics to Prometheus"
  
  @impl true
  def observe_event(event_type, metadata) do
    # Convert event to Prometheus metric
    case event_type do
      :deployment_started ->
        increment_counter("cul8er_deployments_total", metadata)
      
      :deployment_completed ->
        increment_counter("cul8er_deployments_success_total", metadata)
        observe_histogram("cul8er_deployment_duration_seconds", metadata.duration)
      
      :deployment_failed ->
        increment_counter("cul8er_deployments_failed_total", metadata)
      
      _ ->
        :ok
    end
  end
  
  @impl true
  def report_metric(metric_name, value, tags) do
    # Send to Prometheus Pushgateway
    url = "http://localhost:9091/metrics/job/cul8er"
    
    metric = format_metric(metric_name, value, tags)
    
    HTTPoison.post(url, metric)
    
    :ok
  end
  
  @impl true
  def health_status(topology) do
    # Return Prometheus-compatible health status
    %{
      status: "healthy",
      checks: %{
        prometheus: "up"
      }
    }
  end
  
  defp increment_counter(name, metadata) do
    # Increment Prometheus counter
  end
  
  defp observe_histogram(name, value) do
    # Observe histogram value
  end
  
  defp format_metric(name, value, tags) do
    # Format as Prometheus exposition format
  end
end
```

---

## Implementation Guide

### Phase 6.1: Plugin Foundation (Week 12, 20-25 hours)

**Goal:** Basic plugin system working

**Tasks:**
- [ ] Create plugin behaviours
- [ ] Implement plugin registry
- [ ] Add plugin discovery
- [ ] Create plugin lifecycle manager
- [ ] Write plugin tests

**Deliverables:**
- Plugins can register themselves
- Registry validates plugin contracts
- Plugins can be loaded/unloaded

### Phase 6.2: Built-in Plugins (Week 13, 20-25 hours)

**Goal:** Convert existing code to plugins

**Tasks:**
- [ ] Convert strategies to plugins (rolling, blue-green, canary)
- [ ] Convert Incus platform to plugin
- [ ] Convert Telemetry observer to plugin
- [ ] Add Prometheus observer plugin
- [ ] Test all built-in plugins

**Deliverables:**
- All existing functionality works as plugins
- Plugins are swappable
- Documentation updated

### Phase 6.3: Multi-Tenant SaaS (Week 14-15, 40-50 hours)

**Goal:** Full multi-tenant support

**Tasks:**
- [ ] Implement tenant management
- [ ] Create subscription plan system
- [ ] Build tenant provisioner behaviour
- [ ] Implement container-per-tenant plugin
- [ ] Add usage metering
- [ ] Implement tenant isolation
- [ ] Create billing integration
- [ ] Add auto-scaling based on plan
- [ ] Write comprehensive tests

**Deliverables:**
- Tenants can sign up and get resources
- Resources auto-scale with subscription
- Usage is metered and billed
- Tenants are isolated from each other

### Phase 6.4: Plugin Ecosystem (Week 16, 15-20 hours)

**Goal:** Enable third-party plugins

**Tasks:**
- [ ] Create plugin template/generator
- [ ] Write plugin development guide
- [ ] Add plugin validation CLI
- [ ] Create example plugins
- [ ] Set up plugin repository
- [ ] Document plugin API

**Deliverables:**
- Developers can create plugins easily
- Plugin submission process defined
- Example plugins published

---

## Testing Strategies

### Unit Tests

```elixir
defmodule CUL8er.Plugin.RegistryTest do
  use ExUnit.Case
  
  test "registers valid plugin" do
    defmodule TestPlugin do
      use CUL8er.Plugin.Strategy
      
      def deploy(_, _, _), do: {:ok, %{}}
      def rollback(_, _, _), do: {:ok, %{}}
      def health_check(_, _), do: :healthy
    end
    
    assert :ok = CUL8er.Plugin.Registry.register(
      TestPlugin,
      :strategy,
      %{name: :test_strategy, version: "1.0.0"}
    )
  end
  
  test "rejects plugin with missing callbacks" do
    defmodule InvalidPlugin do
      use CUL8er.Plugin.Strategy
      
      def deploy(_, _, _), do: {:ok, %{}}
      # Missing rollback/2 and health_check/2
    end
    
    assert {:error, {:missing_callbacks, _}} = 
      CUL8er.Plugin.Registry.register(
        InvalidPlugin,
        :strategy,
        %{name: :invalid, version: "1.0.0"}
      )
  end
end
```

### Integration Tests

```elixir
@moduletag :integration

defmodule CUL8er.Plugin.IntegrationTest do
  use ExUnit.Case
  
  test "tenant lifecycle with container-per-tenant plugin" do
    # Create tenant
    {:ok, tenant} = CUL8er.SaaS.Tenant.create(%{
      name: "Test Corp",
      subscription_plan: :starter
    })
    
    # Provision (should create container)
    {:ok, resources} = CUL8er.SaaS.provision_tenant(tenant.id)
    
    assert resources.container
    assert resources.database
    
    # Verify container exists
    {:ok, instances} = CUL8er.Core.Incus.list_instances("localhost")
    assert Enum.any?(instances, &(&1.name == "tenant-#{tenant.id}"))
    
    # Upgrade plan
    {:ok, _} = CUL8er.SaaS.upgrade_tenant(tenant.id, :pro)
    
    # Verify limits updated
    {:ok, info} = CUL8er.Core.Incus.info_instance("localhost", "tenant-#{tenant.id}")
    assert info.config["limits.cpu"] == "8"
    
    # Meter usage
    {:ok, usage} = CUL8er.SaaS.meter_tenant(tenant.id)
    assert usage.cpu > 0
    
    # Deprovision
    :ok = CUL8er.SaaS.deprovision_tenant(tenant.id)
    
    # Verify cleanup
    {:ok, instances} = CUL8er.Core.Incus.list_instances("localhost")
    refute Enum.any?(instances, &(&1.name == "tenant-#{tenant.id}"))
  end
end
```

---

## Mix Tasks

### Plugin Management

```elixir
defmodule Mix.Tasks.CUL8er.Plugin do
  use Mix.Task
  
  @shortdoc "Manage plugins"
  
  def run(["list"]) do
    Mix.Task.run("app.start")
    
    plugins = CUL8er.Plugin.Registry.list_all_plugins()
    
    IO.puts("\nInstalled Plugins:\n")
    
    Enum.each(plugins, fn {type, plugins_of_type} ->
      IO.puts("#{type}:")
      
      Enum.each(plugins_of_type, fn {name, {module, metadata}} ->
        IO.puts("  - #{name} (#{metadata.version})")
        IO.puts("    #{metadata.description}")
        IO.puts("    Module: #{inspect(module)}")
      end)
      
      IO.puts("")
    end)
  end
  
  def run(["validate", plugin_file]) do
    # Compile and validate plugin
    Code.compile_file(plugin_file)
    
    IO.puts("✓ Plugin valid")
  end
  
  def run(["install", plugin_name]) do
    # Install plugin from repository
    Mix.Shell.IO.info("Installing #{plugin_name}...")
  end
  
  def run(_) do
    IO.puts("""
    Usage:
      mix c_u_l8er.plugin list              List installed plugins
      mix c_u_l8er.plugin validate FILE     Validate plugin
      mix c_u_l8er.plugin install NAME      Install plugin
    """)
  end
end
```

---

## Summary

This plugin architecture provides:

### For Deployment Extensions
✅ Custom deployment strategies  
✅ Multiple platform support  
✅ Flexible observability  
✅ Third-party integrations

### For Multi-Tenant SaaS
✅ Automatic tenant provisioning  
✅ Subscription-based resources  
✅ Usage metering & billing  
✅ Strict tenant isolation  
✅ Auto-scaling based on plan

### Developer Experience
✅ Type-safe plugin contracts  
✅ Auto-registration  
✅ Easy to create plugins  
✅ Comprehensive testing  
✅ Well-documented API

### Security & Reliability
✅ Sandboxed execution  
✅ Permission system  
✅ Tenant isolation  
✅ Resource quotas  
✅ Audit logging

**Next Steps:**
1. Implement Phase 6.1 (Plugin Foundation)
2. Convert existing code to plugins (Phase 6.2)
3. Build multi-tenant support (Phase 6.3)
4. Enable plugin ecosystem (Phase 6.4)

**Timeline:** 4 weeks (95-120 hours)

---

**Status:** Design Complete ✅  
**Phase:** 6 (Post-MVP)  
**Dependencies:** Phases 1-5 complete
