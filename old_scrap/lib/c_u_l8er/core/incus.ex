defmodule CUL8er.Core.Incus do
  @moduledoc """
  Incus CLI integration for container and VM management.

  Provides functions to interact with Incus (LXD fork) for creating,
  managing, and deploying containers and VMs on local and remote hosts.
  """

  alias CUL8er.DSL.Host

  @type host :: %Host{}
  @type instance_name :: String.t()
  @type command :: String.t()
  @type result :: {:ok, term()} | {:error, term()}

  @doc """
  Executes a command on the specified host.
  @doc """
  Executes a command on the specified host.

  For local hosts, runs the command directly.
  For remote hosts, uses SSH if configured.
  """
  @spec execute(host(), command()) :: result()
  def execute(%Host{address: _address} = _host, command) do
    case System.cmd("incus", String.split(command, " "), stderr_to_stdout: true) do
      {output, 0} -> {:ok, output}
      {error, _code} -> {:error, error}
    end
  end
  # def execute(%Host{} = host, command) do
  #   # For remote hosts, use SSH
  #   # This requires SSH credentials to be configured
  #   ssh_cmd = "ssh #{host.address} incus #{command}"
  #
  #   case System.cmd("sh", ["-c", ssh_cmd], stderr_to_stdout: true) do
  #     {output, 0} -> {:ok, output}
  #     {error, _code} -> {:error, error}
  #   end
  # end
  @doc """
  Starts an Incus instance.
  """
  @spec start_instance(host(), instance_name()) :: result()
  def start_instance(host, name) do
    execute(host, "start #{name}")
  end

  @doc """
  Stops an Incus instance.
  """
  @spec stop_instance(host(), instance_name()) :: result()
  def create_instance(host, name, image, opts \\ []) do
    type = Keyword.get(opts, :type, "container")
    profile = Keyword.get(opts, :profile, "")

    cmd = if type == "container" do
      "launch #{image} #{name} -c security.privileged=true"
    else
      "launch #{image} #{name} --vm"
    IO.puts("Incus create_instance: #{cmd}")

    execute(host, cmd)
  end

    execute(host, cmd)
  end
  """
  @spec exec_instance(host(), instance_name(), command()) :: result()
  def exec_instance(host, name, command) do
    execute(host, "exec #{name} -- #{command}")
  end

  @doc """
  Copies a file from host to instance.
  """
  def push_file(host, src, dest) do
    execute(host, "file push #{src} #{dest}")
  end

  @doc """
  Copies a file from instance to host.
  """
  def pull_file(host, src, dest) do
    execute(host, "file pull #{src} #{dest}")
  end

  @doc """
  Creates a snapshot of an instance.
  """
  @spec create_snapshot(host(), instance_name(), String.t()) :: result()
  def create_snapshot(host, name, snapshot_name) do
    execute(host, "snapshot #{name} #{snapshot_name}")
  end

  @doc """
  Restores an instance from a snapshot.
  """
  @spec restore_snapshot(host(), instance_name(), String.t()) :: result()
  def restore_snapshot(host, name, snapshot_name) do
    execute(host, "restore #{name} #{snapshot_name}")
  end

  @doc """
  Configures instance settings.
  """
  @spec set_config(host(), instance_name(), keyword()) :: result()
  def set_config(host, name, config) do
    config_str = Enum.map_join(config, " ", fn {k, v} -> "--config #{k}=#{v}" end)
    execute(host, "config set #{name} #{config_str}")
  end

  @doc """
  Gets the state of an instance.
  """
  @spec get_state(host(), instance_name()) :: result()
  def get_state(host, name) do
    execute(host, "info #{name} --format json")
  end
end
