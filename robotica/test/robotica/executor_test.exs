defmodule Robotica.Executor.Test do
  use ExUnit.Case, async: true

  setup do
    executor = start_supervised!({Robotica.Executor, name: Robotica.Executor})
    %{executor: executor}
  end

  test "lookup location", %{executor: executor} do
    assert Robotica.Executor.lookup(executor, ["NorthPole"], []) == []
    assert Robotica.Executor.lookup(executor, ["NorthPole"], ["Santa"]) == []
    assert Robotica.Executor.lookup(executor, ["NorthPole"], ["Santa", "Easter Bunny"]) == []
  end

  test "add plugin to location", %{executor: executor} do
    config = %Robotica.Plugins.Logging.Config{}

    plugin = %Robotica.Plugin{
      module: Robotica.Plugins.Logging,
      location: "SouthPole",
      device: "Santa",
      config: config
    }

    {:ok, pid} = start_supervised({plugin.module, plugin})
    assert [] = Robotica.Executor.lookup(executor, ["SouthPole"], [])
    assert [^pid] = Robotica.Executor.lookup(executor, ["SouthPole"], nil)
    assert [^pid] = Robotica.Executor.lookup(executor, ["SouthPole"], ["Santa"])
    assert [^pid] = Robotica.Executor.lookup(executor, ["SouthPole"], ["Santa", "Easter Bunny"])
  end

  test "stops plugin on exit", %{executor: executor} do
    config = %Robotica.Plugins.Logging.Config{}

    plugin = %Robotica.Plugin{
      module: Robotica.Plugins.Logging,
      location: "SouthPole",
      device: "Santa",
      config: config
    }

    {:ok, pid} = start_supervised({plugin.module, plugin})
    assert [^pid] = Robotica.Executor.lookup(executor, ["SouthPole"], nil)

    stop_supervised(plugin.module)
    assert [] = Robotica.Executor.lookup(executor, ["SouthPole"], nil)
  end
end
