defmodule CUL8er.Plugin.Registry do
  @moduledoc """
  Registry for managing C U L8er plugins.

  Handles plugin discovery, registration, and lookup for different plugin types
  like strategies, platforms, observers, etc.
  """

  use GenServer

  @type plugin_type ::
          :strategy
          | :platform
          | :observer
          | :tenant_provisioner
          | :secrets_provider
          | :load_balancer
  @type plugin_name :: atom()
  @type plugin_module :: module()
  @type plugin_metadata :: map()

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Registers a plugin with the registry.
  """
  @spec register(plugin_module(), plugin_type(), plugin_metadata()) :: :ok | {:error, term()}
  def register(plugin_module, type, metadata) do
    GenServer.call(__MODULE__, {:register, plugin_module, type, metadata})
  end

  @doc """
  Gets a plugin by type and name.
  """
  @spec get_plugin(plugin_type(), plugin_name()) :: {:ok, plugin_module()} | {:error, :not_found}
  def get_plugin(type, name) do
    GenServer.call(__MODULE__, {:get_plugin, type, name})
  end

  @doc """
  Lists all plugins of a given type.
  """
  @spec list_plugins(plugin_type()) :: [plugin_name()]
  def list_plugins(type) do
    GenServer.call(__MODULE__, {:list_plugins, type})
  end

  @doc """
  Lists all registered plugin types.
  """
  @spec list_types() :: [plugin_type()]
  def list_types() do
    GenServer.call(__MODULE__, :list_types)
  end

  # GenServer callbacks

  @impl true
  def init(_opts) do
    # Initialize registry as a map of type -> name -> module
    registry = %{}

    # Discover and register built-in plugins
    registry = discover_plugins(registry)

    {:ok, registry}
  end

  @impl true
  def handle_call({:register, plugin_module, type, metadata}, _from, registry) do
    # Validate the plugin
    case validate_plugin(plugin_module, type) do
      :ok ->
        name = metadata[:name] || plugin_module

        new_registry =
          put_in(registry, [type, name], %{module: plugin_module, metadata: metadata})

        {:reply, :ok, new_registry}

      {:error, reason} ->
        {:reply, {:error, reason}, registry}
    end
  end

  @impl true
  def handle_call({:get_plugin, type, name}, _from, registry) do
    case get_in(registry, [type, name]) do
      %{module: module} -> {:reply, {:ok, module}, registry}
      nil -> {:reply, {:error, :not_found}, registry}
    end
  end

  @impl true
  def handle_call({:list_plugins, type}, _from, registry) do
    plugins = registry |> Map.get(type, %{}) |> Map.keys()
    {:reply, plugins, registry}
  end

  @impl true
  def handle_call(:list_types, _from, registry) do
    types = Map.keys(registry)
    {:reply, types, registry}
  end

  # Private functions

  defp discover_plugins(registry) do
    # For now, don't register any plugins - they don't exist yet
    # In Phase 3, we'll create the strategy modules and register them here
    registry
  end

  defp validate_plugin(plugin_module, _type) do
    # Basic validation - check if module exists and has required callbacks
    # This is a simplified version; real validation would check behaviours

    if Code.ensure_loaded?(plugin_module) do
      :ok
    else
      {:error, :module_not_found}
    end
  end
end
