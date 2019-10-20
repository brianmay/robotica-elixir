defmodule RoboticaNerves.MixProject do
  use Mix.Project

  @app :robotica_nerves
  @target System.get_env("MIX_TARGET") || "host"

  def project do
    [
      app: @app,
      version: "0.1.0",
      elixir: "~> 1.4",
      target: @target,
      archives: [nerves_bootstrap: "~> 1.6"],
      deps_path: "deps/#{@target}",
      build_path: "_build/#{@target}",
      lockfile: "mix.lock.#{@target}",
      start_permanent: Mix.env() == :prod,
      aliases: [loadconfig: [&bootstrap/1]],
      deps: deps(),
      releases: [{@app, release()}],
      preferred_cli_target: [run: :host, test: :host]
    ]
  end

  def release do
    [
      overwrite: true,
      cookie: "#{@app}_cookie",
      include_erts: &Nerves.Release.erts/0,
      steps: [&Nerves.Release.init/1, :assemble],
      strip_beams: Mix.env() == :prod
    ]
  end

  # Starting nerves_bootstrap adds the required aliases to Mix.Project.config()
  # Aliases are only added if MIX_TARGET is set.
  def bootstrap(args) do
    Application.start(:nerves_bootstrap)
    Mix.Task.run("loadconfig", args)
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {RoboticaNerves.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:nerves, "~> 1.5", runtime: false},
      {:shoehorn, "~> 0.6"},
      {:robotica, path: "../robotica"},
      {:robotica_plugins, git: "https://github.com/brianmay/robotica-plugins.git"},
      {:robotica_ui, path: "../robotica_ui"},
      {:robotica_face, path: "../robotica_face"},
      {:ring_logger, "~> 0.6"},
      {:toolshed, "~> 0.2"}
    ] ++ deps(@target)
  end

  # Specify target specific dependencies
  defp deps("host") do
    [
      {:scenic_driver_glfw, "~> 0.10"}
    ]
  end

  defp deps("rpi3" = target) do
    deps_nerves() ++
      [
        {:scenic_driver_nerves_rpi, "~> 0.10"},
        {:scenic_driver_nerves_touch, "~> 0.10"}
      ] ++ system(target)
  end

  defp deps("rpi2" = target) do
    deps_nerves() ++ system(target)
  end

  defp deps_nerves() do
    [
      {:nerves_runtime, "~> 0.6"},
      {:nerves_network, "~> 0.3"},
      {:nerves_time, "~> 0.3"},
      {:nerves_init_gadget, "~> 0.4"},
      {:dns, "~> 2.1.2"}
    ]
  end

  defp system("rpi"), do: [{:nerves_system_rpi, "~> 1.8", runtime: false}]
  defp system("rpi0"), do: [{:nerves_system_rpi0, "~> 1.8", runtime: false}]
  defp system("rpi2"), do: [{:nerves_system_rpi2, "~> 1.8", runtime: false}]
  defp system("rpi3"), do: [{:robotica_rpi3, "~> 1.8", runtime: false}]
  defp system("bbb"), do: [{:nerves_system_bbb, "~> 2.3", runtime: false}]
  defp system("ev3"), do: [{:nerves_system_ev3, "~> 1.8", runtime: false}]
  defp system("qemu_arm"), do: [{:nerves_system_qemu_arm, "~> 1.8", runtime: false}]
  defp system("x86_64"), do: [{:nerves_system_x86_64, "~> 1.8", runtime: false}]
  defp system(target), do: Mix.raise("Unknown MIX_TARGET: #{target}")
end
