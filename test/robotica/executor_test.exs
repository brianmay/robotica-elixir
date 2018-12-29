defmodule Robotica.Executor.Test do
  use ExUnit.Case, async: true

  setup do
    executor = start_supervised!(Robotica.Executor)
    %{executor: executor}
  end

  test "lookup location", %{executor: executor} do
    assert Robotica.Executor.lookup(executor, "NorthPole") == []
  end

  test "add plugin to location", %{executor: executor} do
    config = %Robotica.Plugins.Logging.Config{}

    plugin = %Robotica.Plugins.Plugin{
      module: Robotica.Plugins.Logging,
      location: "SouthPole",
      config: config,
      executor: executor
    }

    {:ok, pid} = start_supervised({plugin.module, plugin})
    assert [^pid] = Robotica.Executor.lookup(executor, "SouthPole")
  end

  test "stops plugin on exit", %{executor: executor} do
    config = %Robotica.Plugins.Logging.Config{}

    plugin = %Robotica.Plugins.Plugin{
      module: Robotica.Plugins.Logging,
      location: "SouthPole",
      config: config,
      executor: executor
    }

    {:ok, pid} = start_supervised({plugin.module, plugin})
    assert [^pid] = Robotica.Executor.lookup(executor, "SouthPole")

    stop_supervised(plugin.module)
    assert [] = Robotica.Executor.lookup(executor, "SouthPole")
  end
end
