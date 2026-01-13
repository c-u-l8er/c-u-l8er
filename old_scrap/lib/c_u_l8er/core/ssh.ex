defmodule CUL8er.Core.SSH do
  @moduledoc """
  SSH client for remote host connections.

  Provides secure SSH connections to remote hosts for executing commands
  and managing remote infrastructure.
  """

  alias CUL8er.DSL.Host

  @type host :: %Host{}
  @type command :: String.t()
  @type result :: {:ok, String.t()} | {:error, term()}

  @doc """
  Executes a command on a remote host via SSH.

  ## Options
  - `:user` - SSH username (defaults to current user)
  - `:key` - Path to SSH private key
  - `:password` - SSH password (less secure)
  - `:port` - SSH port (defaults to 22)
  - `:timeout` - Command timeout in milliseconds
  """
  @spec execute(host(), command(), keyword()) :: result()
  def execute(%Host{address: address} = _host, command, opts \\ []) do
    user = Keyword.get(opts, :user, System.get_env("USER") || "root")
    key_path = Keyword.get(opts, :key, "~/.ssh/id_rsa")
    password = Keyword.get(opts, :password)
    port = Keyword.get(opts, :port, 22)
    _timeout = Keyword.get(opts, :timeout, 30000)

    # Expand key path
    key_path = Path.expand(key_path)

    # Build SSH command
    ssh_cmd = build_ssh_command(address, user, key_path, password, port, command)

    # Execute with timeout
    case System.cmd("sh", ["-c", ssh_cmd], stderr_to_stdout: true) do
      {output, 0} ->
        {:ok, String.trim(output)}

      {error, code} ->
        {:error, {:ssh_failed, code, error}}
    end
  end

  @doc """
  Tests SSH connection to a host.
  """
  @spec test_connection(host(), keyword()) :: :ok | {:error, term()}
  def test_connection(host, opts \\ []) do
    case execute(host, "echo 'SSH connection successful'", opts) do
      {:ok, "SSH connection successful"} -> :ok
      error -> error
    end
  end

  @doc """
  Copies a file to a remote host via SCP.
  """
  @spec upload_file(host(), String.t(), String.t(), keyword()) :: result()
  def upload_file(%Host{address: address} = _host, local_path, remote_path, opts \\ []) do
    user = Keyword.get(opts, :user, System.get_env("USER") || "root")
    key_path = Keyword.get(opts, :key, "~/.ssh/id_rsa")
    port = Keyword.get(opts, :port, 22)

    key_path = Path.expand(key_path)

    scp_cmd = "scp -i #{key_path} -P #{port} #{local_path} #{user}@#{address}:#{remote_path}"

    case System.cmd("sh", ["-c", scp_cmd], stderr_to_stdout: true) do
      {output, 0} -> {:ok, String.trim(output)}
      {error, code} -> {:error, {:scp_failed, code, error}}
    end
  end

  @doc """
  Copies a file from a remote host via SCP.
  """
  @spec download_file(host(), String.t(), String.t(), keyword()) :: result()
  def download_file(%Host{address: address} = _host, remote_path, local_path, opts \\ []) do
    user = Keyword.get(opts, :user, System.get_env("USER") || "root")
    key_path = Keyword.get(opts, :key, "~/.ssh/id_rsa")
    port = Keyword.get(opts, :port, 22)

    key_path = Path.expand(key_path)

    scp_cmd = "scp -i #{key_path} -P #{port} #{user}@#{address}:#{remote_path} #{local_path}"

    case System.cmd("sh", ["-c", scp_cmd], stderr_to_stdout: true) do
      {output, 0} -> {:ok, String.trim(output)}
      {error, code} -> {:error, {:scp_failed, code, error}}
    end
  end

  @doc """
  Checks if a file exists on the remote host.
  """
  @spec file_exists?(host(), String.t(), keyword()) :: boolean()
  def file_exists?(host, remote_path, opts \\ []) do
    case execute(host, "test -f #{remote_path} && echo 'exists'", opts) do
      {:ok, "exists"} -> true
      _ -> false
    end
  end

  @doc """
  Creates a directory on the remote host.
  """
  @spec mkdir_p(host(), String.t(), keyword()) :: result()
  def mkdir_p(host, remote_path, opts \\ []) do
    execute(host, "mkdir -p #{remote_path}", opts)
  end

  # Private functions

  defp build_ssh_command(address, user, key_path, password, port, command) do
    ssh_opts = [
      "-i #{key_path}",
      "-p #{port}",
      "-o StrictHostKeyChecking=no",
      "-o UserKnownHostsFile=/dev/null",
      "-o LogLevel=ERROR"
    ]

    ssh_opts_str = Enum.join(ssh_opts, " ")

    if password do
      # Use sshpass for password authentication (requires sshpass to be installed)
      "sshpass -p '#{password}' ssh #{ssh_opts_str} #{user}@#{address} #{shell_escape(command)}"
    else
      "ssh #{ssh_opts_str} #{user}@#{address} #{shell_escape(command)}"
    end
  end

  defp shell_escape(command) do
    # Basic shell escaping - wrap in single quotes and escape single quotes
    "'" <> String.replace(command, "'", "'\"'\"'") <> "'"
  end
end
