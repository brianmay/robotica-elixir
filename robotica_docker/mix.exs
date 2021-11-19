defmodule RoboticaDocker.MixProject do
  use Mix.Project

  def project do
    [
      app: :robotica_docker,
      version: "0.1.0",
      elixir: "~> 1.10",
      elixirc_options: [warnings_as_errors: true],
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      elixirc_options: [warnings_as_errors: true],
      dialyzer: dialyzer()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {RoboticaDocker.Application, []},
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:robotica, path: "../robotica"},
      {:robotica_common, path: "../robotica_common"},
      {:robotica_face, path: "../robotica_face"},
      {:libcluster, "~> 3.3"},
      {:cowlib, "~> 2.11", override: true},
      {:gun, "~> 1.3", override: true},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:credo, "~> 1.6.1", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.1.0", only: [:dev, :test], runtime: false}
    ]
  end

  defp aliases do
    [
      test: "test --no-start"
    ]
  end

  defp dialyzer do
    [
      plt_core_path: "priv/plts",
      plt_file: {:no_warn, "priv/plts/dialyzer.plt"},
      plt_add_apps: [:ex_unit]
    ]
  end
end
