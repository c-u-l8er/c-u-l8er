defmodule CUL8er.Security.Secrets do
  @moduledoc """
  Manages encrypted secrets for topologies.

  Provides secure storage and retrieval of sensitive configuration data
  like passwords, API keys, and certificates.
  """

  use GenServer

  @type topology_name :: atom()
  @type secret_key :: String.t()
  @type secret_value :: String.t()

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Stores an encrypted secret for a topology.
  """
  @spec store(topology_name(), secret_key(), secret_value()) :: :ok | {:error, term()}
  def store(topology, key, value) do
    GenServer.call(__MODULE__, {:store, topology, key, value})
  end

  @doc """
  Retrieves a decrypted secret for a topology.
  """
  @spec retrieve(topology_name(), secret_key()) :: {:ok, secret_value()} | {:error, term()}
  def retrieve(topology, key) do
    GenServer.call(__MODULE__, {:retrieve, topology, key})
  end

  @doc """
  Lists all secrets for a topology.
  """
  @spec list_keys(topology_name()) :: [secret_key()]
  def list_keys(topology) do
    GenServer.call(__MODULE__, {:list_keys, topology})
  end

  # GenServer callbacks

  @impl true
  def init(opts) do
    secrets_dir = Keyword.get(opts, :secrets_dir, "~/.c_u_l8er/secrets")
    secrets_dir = Path.expand(secrets_dir)

    # Ensure secrets directory exists
    File.mkdir_p!(secrets_dir)

    # Get master key from environment or generate one
    master_key = System.get_env("MASTER_KEY") || generate_master_key()

    {:ok,
     %{
       secrets_dir: secrets_dir,
       master_key: master_key
     }}
  end

  @impl true
  def handle_call(
        {:store, topology, key, value},
        _from,
        %{secrets_dir: secrets_dir, master_key: master_key} = state
      ) do
    result = do_store(secrets_dir, topology, key, value, master_key)
    {:reply, result, state}
  end

  @impl true
  def handle_call(
        {:retrieve, topology, key},
        _from,
        %{secrets_dir: secrets_dir, master_key: master_key} = state
      ) do
    result = do_retrieve(secrets_dir, topology, key, master_key)
    {:reply, result, state}
  end

  @impl true
  def handle_call({:list_keys, topology}, _from, %{secrets_dir: secrets_dir} = state) do
    keys = do_list_keys(secrets_dir, topology)
    {:reply, keys, state}
  end

  # Private functions

  defp do_store(secrets_dir, topology, key, value, master_key) do
    topology_dir = Path.join(secrets_dir, Atom.to_string(topology))
    File.mkdir_p!(topology_dir)

    file_path = Path.join(topology_dir, key <> ".enc")

    case encrypt(value, master_key) do
      {:ok, encrypted} ->
        case File.write(file_path, encrypted) do
          :ok -> :ok
          {:error, reason} -> {:error, {:file_write_failed, reason}}
        end

      {:error, reason} ->
        {:error, {:encryption_failed, reason}}
    end
  end

  defp do_retrieve(secrets_dir, topology, key, master_key) do
    topology_dir = Path.join(secrets_dir, Atom.to_string(topology))
    file_path = Path.join(topology_dir, key <> ".enc")

    case File.read(file_path) do
      {:ok, encrypted} ->
        case decrypt(encrypted, master_key) do
          {:ok, decrypted} -> {:ok, decrypted}
          {:error, reason} -> {:error, {:decryption_failed, reason}}
        end

      {:error, :enoent} ->
        {:error, :not_found}

      {:error, reason} ->
        {:error, {:file_read_failed, reason}}
    end
  end

  defp do_list_keys(secrets_dir, topology) do
    topology_dir = Path.join(secrets_dir, Atom.to_string(topology))

    case File.ls(topology_dir) do
      {:ok, files} ->
        files
        |> Enum.filter(&String.ends_with?(&1, ".enc"))
        |> Enum.map(&String.replace_suffix(&1, ".enc", ""))

      {:error, _reason} ->
        []
    end
  end

  defp encrypt(plaintext, key) do
    # Use a simple encryption for now - in production, use proper AES
    # This is just for demonstration - real implementation should use proper crypto
    salt = "fixed_salt_for_demo"
    combined_key = :crypto.hash(:sha256, key <> salt)
    encrypted = :crypto.exor(plaintext, binary_part(combined_key, 0, byte_size(plaintext)))
    {:ok, salt <> encrypted}
  rescue
    _ -> {:error, :encryption_failed}
  end

  defp decrypt(ciphertext, key) do
    try do
      salt_size = byte_size("fixed_salt_for_demo")
      <<_salt::binary-size(salt_size), encrypted::binary>> = ciphertext
      combined_key = :crypto.hash(:sha256, key <> "fixed_salt_for_demo")
      decrypted = :crypto.exor(encrypted, binary_part(combined_key, 0, byte_size(encrypted)))
      {:ok, decrypted}
    rescue
      _ -> {:error, :decryption_failed}
    end
  end

  defp generate_master_key do
    # Generate a random 32-byte key and encode as hex
    :crypto.strong_rand_bytes(32)
    |> Base.encode16(case: :lower)
  end
end
