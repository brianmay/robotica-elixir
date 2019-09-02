defmodule Robotica.Executor.Test do
  use ExUnit.Case, async: true

  setup do
    executor = start_supervised!(RoboticaPlugins.Executor)
    %{executor: executor}
  end

  test "lookup location", %{executor: executor} do
    assert RoboticaPlugins.Executor.lookup(executor, "NorthPole") == []
  end

  test "add plugin to location", %{executor: executor} do
    config = %Robotica.Plugins.Logging.Config{}

    plugin = %RoboticaPlugins.Plugin{
      module: Robotica.Plugins.Logging,
      location: "SouthPole",
      config: config,
      executor: executor
    }

    {:ok, pid} = start_supervised({plugin.module, plugin})
    assert [^pid] = RoboticaPlugins.Executor.lookup(executor, "SouthPole")
  end

  test "stops plugin on exit", %{executor: executor} do
    config = %Robotica.Plugins.Logging.Config{}

    plugin = %RoboticaPlugins.Plugin{
      module: Robotica.Plugins.Logging,
      location: "SouthPole",
      config: config,
      executor: executor
    }

    {:ok, pid} = start_supervised({plugin.module, plugin})
    assert [^pid] = RoboticaPlugins.Executor.lookup(executor, "SouthPole")

    stop_supervised(plugin.module)
    assert [] = RoboticaPlugins.Executor.lookup(executor, "SouthPole")
  end
end
