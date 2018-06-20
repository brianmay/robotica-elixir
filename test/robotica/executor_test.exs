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
    config = %Robotica.Plugins.Logging.State{}

    plugin = %Robotica.Plugins.Plugin{
      module: Robotica.Plugins.Logging,
      location: "SouthPole",
      config: config,
      register: fn pid ->
        Robotica.Executor.add(executor, "NorthPole", pid)
      end
    }

    {:ok, pid} = DynamicSupervisor.start_child(:dynamic, {plugin.module, plugin})
    assert [^pid] = Robotica.Executor.lookup(executor, "NorthPole")
  end

  test "stops plugin on exit", %{executor: executor} do
    config = %Robotica.Plugins.Logging.State{}

    plugin = %Robotica.Plugins.Plugin{
      module: Robotica.Plugins.Logging,
      location: "SouthPole",
      config: config,
      register: fn pid ->
        Robotica.Executor.add(executor, "NorthPole", pid)
      end
    }

    {:ok, pid} = DynamicSupervisor.start_child(:dynamic, {plugin.module, plugin})
    assert [^pid] = Robotica.Executor.lookup(executor, "NorthPole")

    Supervisor.stop(pid)
    assert [] = Robotica.Executor.lookup(executor, "NorthPole")
  end
end
