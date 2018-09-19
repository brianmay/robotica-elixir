defmodule Robotica.MixProject do
  use Mix.Project

  def project do
    [
      app: :robotica,
      version: "0.1.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
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
      {:poison, "~> 3.1"},
      {:tortoise, "~> 0.9.2"},
      {:dialyxir, "~> 1.0.0-rc.2", only: [:dev], runtime: false},
      {:lifx, path: "../lifx"},
      {:yaml_elixir, "~> 2.1.0"},
      {:calendar, "~> 0.17.2"}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"},
    ]
  end
end
