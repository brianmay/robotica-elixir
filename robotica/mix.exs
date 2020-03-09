defmodule Robotica.MixProject do
  use Mix.Project

  def project do
    [
      app: :robotica,
      version: "0.1.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Robotica, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:poison, "~> 4.0.1"},
      {:tortoise, "~> 0.9.2"},
      {:dialyxir, "~> 1.0.0-rc.2", only: [:dev], runtime: false},
      {:credo, "~> 1.3.0", only: [:dev, :test], runtime: false},
      {:lifx, git: "https://github.com/brianmay/lifx.git"},
      {:tp_link_hs100, git: "https://github.com/brianmay/tp_link_hs100.git"},
      {:calendar, "~> 1.0.0"},
      {:yaml_elixir, "~> 2.4.0"},
      {:event_bus, "~> 1.6.0"},
      {:mojito, "~> 0.6.1"},
      {:mint, "~> 1.0", override: true},
      {:robotica_plugins, path: "../robotica_plugins"}
    ]
  end

  defp aliases do
    [
      test: "test --no-start"
    ]
  end
end
