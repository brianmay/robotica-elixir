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
      {:dialyxir, "~> 1.1.0", only: [:dev], runtime: false},
      {:credo, "~> 1.5.5", only: [:dev, :test], runtime: false},
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
