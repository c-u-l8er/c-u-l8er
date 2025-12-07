defmodule CUL8er.MixProject do
  use Mix.Project

  def project do
    [
      app: :c_u_l8er,
      version: "0.1.0",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: Mix.compilers(),
      dialyzer: dialyzer()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :runtime_tools, :ssl, :crypto],
      mod: {CUL8er.Application, []}
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support", "examples"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:jason, "~> 1.4"},
      {:libcluster, "~> 3.3"},
      {:telemetry, "~> 1.0"},
      {:telemetry_metrics, "~> 0.6"},
      {:telemetry_poller, "~> 1.0"},
      # Development and testing
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev], runtime: false},
      {:ex_doc, "~> 0.30", only: :dev, runtime: false},
      {:mox, "~> 1.0", only: :test}
    ]
  end

  defp dialyzer do
    [
      plt_add_apps: [:mix],
      plt_core_path: "_build/#{Mix.env()}/dialyzer/",
      flags: [:unmatched_returns, :error_handling, :race_conditions, :underspecs]
    ]
  end
end
