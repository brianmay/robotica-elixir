defmodule Robotica.MixProject do
  use Mix.Project

  def project do
    [
      app: :robotica,
      version: "0.1.0",
      elixir: "~> 1.6",
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
      extra_applications: [:logger],
      mod: {Robotica, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:mqtt_potion, github: "brianmay/mqtt_potion"},
      {:lifx, git: "https://github.com/brianmay/lifx.git"},
      {:tp_link_hs100, git: "https://github.com/brianmay/tp_link_hs100.git"},
      {:mojito, "~> 0.7.1"},
      {:mint, "~> 1.0", override: true},
      {:robotica_common, path: "../robotica_common"},
      {:credo, "~> 1.6.0", only: [:dev, :test], runtime: false},
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
