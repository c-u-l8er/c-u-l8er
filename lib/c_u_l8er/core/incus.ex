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

  def execute(%Host{} = host, command) do
    # For remote hosts, use SSH
    # This requires SSH credentials to be configured
    ssh_cmd = "ssh #{host.address} incus #{command}"

    case System.cmd("sh", ["-c", ssh_cmd], stderr_to_stdout: true) do
      {output, 0} -> {:ok, output}
      {error, _code} -> {:error, error}
    end
  end

  @doc """
  Gets information about an Incus instance.
  """
  @spec info_instance(host(), instance_name()) :: result()
  def info_instance(host, name) do
    execute(host, "info #{name}")
  end

  @doc """
  Lists all Incus instances on the host.
  """
  @spec list_instances(host()) :: result()
  def list_instances(host) do
    execute(host, "list --format json")
  end

  @doc """
  Creates a new Incus instance from an image.
  """
  @spec create_instance(host(), instance_name(), String.t(), keyword()) :: result()
  def create_instance(host, name, image, opts \\ []) do
    type = Keyword.get(opts, :type, "container")
    profile = Keyword.get(opts, :profile, "")

    cmd = "launch #{image} #{name} --type #{type}"
    cmd = if profile != "", do: cmd <> " --profile #{profile}", else: cmd

    execute(host, cmd)
  end

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
  def stop_instance(host, name) do
    execute(host, "stop #{name}")
  end

  @doc """
  Deletes an Incus instance.
  """
  @spec delete_instance(host(), instance_name()) :: result()
  def delete_instance(host, name) do
    execute(host, "delete #{name}")
  end

  @doc """
  Executes a command inside a running instance.
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
