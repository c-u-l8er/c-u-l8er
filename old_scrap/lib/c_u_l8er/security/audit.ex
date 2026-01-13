
defmodule CUL8er.Security.Audit do
  @moduledoc """
  Security audit logging for C U L8er operations.

  Logs important events like deployments, secret access, topology changes,
  and other security-relevant activities.
  """

  use GenServer

  @type event_type :: atom()
  @type metadata :: map()

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Logs an audit event with metadata.
  """
  @spec log(event_type(), metadata()) :: :ok
  def log(event, metadata \\ %{}) do
    GenServer.cast(__MODULE__, {:log, event, metadata})
  end

  # GenServer callbacks

  @impl true
  def init(opts) do
    log_dir = Keyword.get(opts, :log_dir, "~/.c_u_l8er/logs")
    log_dir = Path.expand(log_dir)

    # Ensure log directory exists
    File.mkdir_p!(log_dir)

    log_file = Keyword.get(opts, :log_file, "audit.log")
    log_path = Path.join(log_dir, log_file)

    # Open log file for appending
    {:ok, file} = File.open(log_path, [:append, :utf8])

    {:ok,
     %{
       log_file: file,
       hostname: get_hostname()
     }}
  end

  @impl true
  def handle_cast({:log, event, metadata}, %{log_file: file, hostname: hostname} = state) do
    timestamp = DateTime.utc_now() |> DateTime.to_iso8601()

    log_entry = %{
      timestamp: timestamp,
      hostname: hostname,
      event: event,
      metadata: metadata
    }

    case Jason.encode(log_entry) do
      {:ok, json} ->
        IO.write(file, json <> "\n")

      {:error, _reason} ->
        # If JSON encoding fails, log a simple text version
        IO.write(file, "#{timestamp} #{hostname} #{event} #{inspect(metadata)}\n")
    end

    {:noreply, state}
  end

  @impl true
  def terminate(_reason, %{log_file: file}) do
    File.close(file)
  end

  # Private functions

  defp get_hostname do
    case :inet.gethostname() do
      {:ok, hostname} -> to_string(hostname)
      _ -> "unknown"
    end
  end
end
