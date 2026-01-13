defmodule CUL8er.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # State management for deployments
      CUL8er.Core.State,
      # Security modules
      CUL8er.Security.Secrets,
      CUL8er.Security.Audit,
      # Plugin registry
      CUL8er.Plugin.Registry
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: CUL8er.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
