defmodule Core.MixProject do
  use Mix.Project

  def project do
    [
      app: :core,
      elixirc_paths: elixirc_paths(Mix.env()),
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {Core.Application, []},
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ecto, "~> 3.5.5"},
      {:ecto_sql, "~> 3.5.3"},
      {:myxql, "~> 0.4.5"},
      {:poison, "~> 4.0.1"},
      {:ex_json_schema, "~> 0.7.4"},
      {:redix, "~> 1.0"},
      {:mock, "~> 0.3", only: :test},
      {:yaml_elixir, "~> 2.5"}
    ]
  end

  defp aliases do
    [
      "core.seed": "core_seed"
    ]
  end
end
