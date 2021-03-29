defmodule Ceryx.MixProject do
  use Mix.Project

  def project do
    [
      app: :ceryx,
      version: "0.1.0",
      elixir: "~> 1.6",
      elixirc_options: [warnings_as_errors: true],
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Ceryx, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:dialyxir, "~> 1.0.0-rc.2", only: [:dev], runtime: false},
      {:credo, "~> 1.2.0", only: [:dev, :test], runtime: false},
      {:calendar, "~> 1.0.0"},
      {:yaml_elixir, "~> 2.6.0"},
      {:event_bus, "~> 1.6.0"},
      {:robotica_common, path: "../robotica_common"}
    ]
  end

  defp aliases do
    [
      test: "test --no-start"
    ]
  end
end
