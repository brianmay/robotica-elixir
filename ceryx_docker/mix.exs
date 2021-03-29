defmodule CeryxDocker.MixProject do
  use Mix.Project

  def project do
    [
      app: :ceryx_docker,
      version: "0.1.0",
      elixir: "~> 1.10",
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
      {:ceryx, path: "../ceryx"},
      {:robotica_common, path: "../robotica_common"},
      {:robotica_face, path: "../robotica_face"}
    ]
  end
end
