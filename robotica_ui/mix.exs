defmodule RoboticaUi.MixProject do
  use Mix.Project

  def project do
    [
      app: :robotica_ui,
      version: "0.1.0",
      elixir: "~> 1.7",
      build_embedded: true,
      start_permanent: Mix.env() == :prod,
      deps: deps()
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
      {:timex, "~> 3.6.0"},
      {:calendar, "~> 1.0.0"},
      {:yaml_elixir, "~> 2.4.0"},
      {:robotica_plugins, git: "https://github.com/brianmay/robotica-plugins.git"}
    ]
  end
end
