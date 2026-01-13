defmodule CUL8er.Core.State do
  @moduledoc """
  Manages deployment state for topologies.

  Tracks the current state of deployed resources, hosts, and topologies.
  Provides persistence and retrieval of deployment state.
  """

  use GenServer

  @type topology_name :: atom()
  @type state_data :: map()

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Saves the state for a topology.
  """
  @spec save(topology_name(), state_data()) :: :ok | {:error, term()}
  def save(topology, state_data) do
    GenServer.call(__MODULE__, {:save, topology, state_data})
  end

  @doc """
  Loads the state for a topology.
  """
  @spec load(topology_name()) :: {:ok, state_data()} | {:error, term()}
  def load(topology) do
    GenServer.call(__MODULE__, {:load, topology})
  end

  @doc """
  Lists all saved topologies.
  """
  @spec list_topologies() :: [topology_name()]
  def list_topologies() do
    GenServer.call(__MODULE__, :list_topologies)
  end

  @doc """
  Deletes the state for a topology.
  """
  @spec delete(topology_name()) :: :ok | {:error, term()}
  def delete(topology) do
    GenServer.call(__MODULE__, {:delete, topology})
  end

  # GenServer callbacks

  @impl true
  def init(opts) do
    state_dir = Keyword.get(opts, :state_dir, "~/.c_u_l8er/state")
    state_dir = Path.expand(state_dir)

    # Ensure state directory exists
    File.mkdir_p!(state_dir)

    {:ok, %{state_dir: state_dir}}
  end

  @impl true
  def handle_call({:save, topology, state_data}, _from, %{state_dir: state_dir} = state) do
    result = do_save(state_dir, topology, state_data)
    {:reply, result, state}
  end

  @impl true
  def handle_call({:load, topology}, _from, %{state_dir: state_dir} = state) do
    result = do_load(state_dir, topology)
    {:reply, result, state}
  end

  @impl true
  def handle_call(:list_topologies, _from, %{state_dir: state_dir} = state) do
    topologies = do_list_topologies(state_dir)
    {:reply, topologies, state}
  end

  @impl true
  def handle_call({:delete, topology}, _from, %{state_dir: state_dir} = state) do
    result = do_delete(state_dir, topology)
    {:reply, result, state}
  end

  # Private functions

  defp do_save(state_dir, topology, state_data) do
    file_path = Path.join(state_dir, "#{topology}.json")

    case Jason.encode(state_data) do
      {:ok, json} ->
        case File.write(file_path, json) do
          :ok -> :ok
          {:error, reason} -> {:error, {:file_write_failed, reason}}
        end

      {:error, reason} ->
        {:error, {:json_encode_failed, reason}}
    end
  end

  defp do_load(state_dir, topology) do
    file_path = Path.join(state_dir, "#{topology}.json")

    case File.read(file_path) do
      {:ok, json} ->
        case Jason.decode(json) do
          {:ok, data} -> {:ok, data}
          {:error, reason} -> {:error, {:json_decode_failed, reason}}
        end

      {:error, :enoent} ->
        {:error, :not_found}

      {:error, reason} ->
        {:error, {:file_read_failed, reason}}
    end
  end

  defp do_list_topologies(state_dir) do
    case File.ls(state_dir) do
      {:ok, files} ->
        files
        |> Enum.filter(&String.ends_with?(&1, ".json"))
        |> Enum.map(&String.replace_suffix(&1, ".json", ""))
        |> Enum.map(&String.to_atom/1)

      {:error, _reason} ->
        []
    end
  end

  defp do_delete(state_dir, topology) do
    file_path = Path.join(state_dir, "#{topology}.json")

    case File.rm(file_path) do
      :ok -> :ok
      {:error, :enoent} -> {:error, :not_found}
      {:error, reason} -> {:error, {:file_delete_failed, reason}}
    end
  end
end
