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
      {:event_bus, "~> 1.6.1"},
      {:timex, "~> 3.6"},
      {:robotica_common, path: "../robotica_common"},
      {:credo, "~> 1.5.5", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.1.0", only: [:dev, :test], runtime: false}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      test: ["test --no-start"],
      prettier: "cmd ./assets/node_modules/.bin/prettier --check . --color"
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
