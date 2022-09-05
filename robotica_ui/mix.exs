defmodule RoboticaUi.MixProject do
  use Mix.Project

  def project do
    [
      app: :robotica_ui,
      version: "0.1.0",
      elixir: "~> 1.7",
      #      elixirc_options: [warnings_as_errors: true],
      build_embedded: true,
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      dialyzer: dialyzer()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {RoboticaUi, []},
      extra_applications: []
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:scenic, "~> 0.10"},
      {:timex, "~> 3.6"},
      {:robotica_common, path: "../robotica_common"},
      {:robotica, path: "../robotica"},
      {:credo, "~> 1.6.0", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.2.0", only: [:dev, :test], runtime: false},
      {:scenic_driver_local, "~> 0.10"}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      test: ["test --no-start"]
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
