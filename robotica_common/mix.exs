defmodule RoboticaCommon.MixProject do
  use Mix.Project

  def project do
    [
      app: :robotica_common,
      version: "0.1.0",
      elixir: "~> 1.8",
      elixirc_options: [warnings_as_errors: true],
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      elixirc_options: [warnings_as_errors: true],
      dialyzer: dialyzer()
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
      {:tzdata, "~> 1.1.0"},
      {:event_bus, "~> 1.7.0"},
      {:jason, "~> 1.0"},
      {:yaml_elixir, "~> 2.9.0"},
      {:credo, "~> 1.7.0", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.3.0", only: [:dev, :test], runtime: false}
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
