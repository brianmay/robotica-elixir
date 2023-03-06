defmodule RoboticaNerves.MixProject do
  use Mix.Project

  @app :robotica_nerves
  @version "0.1.0"
  @all_targets [:rpi, :rpi0, :rpi2, :rpi3, :rpi3a, :rpi4, :bbb, :osd32mp1, :x86_64]

  def project do
    [
      app: @app,
      version: @version,
      elixir: "~> 1.9",
      archives: [nerves_bootstrap: "~> 1.10"],
      start_permanent: Mix.env() == :prod,
      build_embedded: true,
      deps: deps(),
      releases: [{@app, release()}],
      preferred_cli_target: [run: :host, test: :host],
      elixirc_options: [warnings_as_errors: true],
      dialyzer: dialyzer()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {RoboticaNerves.Application, []},
      extra_applications: [
        :logger,
        :runtime_tools,
        :robotica_common,
        :robotica,
        :robotica_ui
      ]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # Dependencies for all targets
      {:nerves, "~> 1.10.0", runtime: false},
      {:shoehorn, "~> 0.9.1"},
      {:ring_logger, "~> 0.9.0"},
      {:toolshed, "~> 0.3.0"},

      # Dependencies for all targets except :host
      {:nerves_runtime, "~> 0.13.0", targets: @all_targets},
      {:nerves_pack, "~> 0.7.0", targets: @all_targets},

      # Dependencies for specific targets
      # NOTE: It's generally low risk and recommended to follow minor version
      # bumps to Nerves systems. Since these include Linux kernel and Erlang
      # version updates, please review their release notes in case
      # changes to your application are needed.
      {:nerves_system_rpi, "~> 1.21", runtime: false, targets: :rpi},
      {:nerves_system_rpi0, "~> 1.21", runtime: false, targets: :rpi0},
      {:nerves_system_rpi2, "~> 1.21", runtime: false, targets: :rpi2},
      {:robotica_rpi3, "~> 1.21", runtime: false, targets: :rpi3},
      {:nerves_system_rpi3a, "~> 1.21", runtime: false, targets: :rpi3a},
      {:nerves_system_rpi4, "~> 1.21", runtime: false, targets: :rpi4},
      {:nerves_system_bbb, "~> 2.14", runtime: false, targets: :bbb},
      {:nerves_system_osd32mp1, "~> 0.10", runtime: false, targets: :osd32mp1},
      {:nerves_system_x86_64, "~> 1.21", runtime: false, targets: :x86_64},
      {:robotica, path: "../robotica"},
      {:robotica_common, path: "../robotica_common"},
      {:robotica_ui, path: "../robotica_ui"},
      {:cowlib, "~> 2.11", override: true},
      {:gun, "~> 2.0", override: true},
      {:credo, "~> 1.6.1", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.2.0", only: [:dev, :test], runtime: false}
    ]
  end

  def release do
    [
      overwrite: true,
      # Erlang distribution is not started automatically.
      # See https://hexdocs.pm/nerves_pack/readme.html#erlang-distribution
      cookie: "#{@app}_cookie",
      include_erts: &Nerves.Release.erts/0,
      steps: [&Nerves.Release.init/1, :assemble],
      strip_beams: Mix.env() == :prod or [keep: ["Docs"]]
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
