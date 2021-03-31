defmodule RoboticaPlugins.MixProject do
  use Mix.Project

  def project do
    [
      app: :robotica_common,
      version: "0.1.0",
      elixir: "~> 1.8",
      elixirc_options: [warnings_as_errors: true],
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:poison, "~> 4.0.1"},
      {:tortoise, "~> 0.9.2"},
      {:tzdata, "~> 1.1.0"},
      {:event_bus, "~> 1.6.0"},
      {:yaml_elixir, "~> 2.6.0"},
      {:dialyxir, "~> 1.1.0", only: [:dev], runtime: false}
    ]
  end
end