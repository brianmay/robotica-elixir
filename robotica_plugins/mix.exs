defmodule RoboticaPlugins.MixProject do
  use Mix.Project

  def project do
    [
      app: :robotica_plugins,
      version: "0.1.0",
      elixir: "~> 1.8",
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
      {:tzdata, "~> 1.0.2"},
      {:event_bus, "~> 1.6.0"},
      {:yaml_elixir, "~> 2.5.0"},
      {:dialyxir, "~> 1.0.0-rc.2", only: [:dev], runtime: false}
    ]
  end
end
