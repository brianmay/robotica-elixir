defmodule Robotica.Registry.Test do
  use ExUnit.Case, async: true

  setup do
    registry = start_supervised!(Robotica.Registry)
    %{registry: registry}
  end

  test "lookup location", %{registry: registry} do
    assert Robotica.Registry.lookup(registry, "NorthPole") == []
  end

  test "add plugin to location", %{registry: registry} do
    config = %Robotica.Plugins.Logging.State{
      location: "SouthPole"
    }

    plugin = start_supervised!({Robotica.Plugins.Logging, config})
    Robotica.Registry.add(registry, "NorthPole", plugin)
    assert Robotica.Registry.lookup(registry, "NorthPole") == [plugin]
  end

  test "removes plugin on exit", %{registry: registry} do
    config = %Robotica.Plugins.Logging.State{
      location: "SouthPole"
    }

    plugin = start_supervised!({Robotica.Plugins.Logging, config})
    Robotica.Registry.add(registry, "NorthPole", plugin)
    assert Robotica.Registry.lookup(registry, "NorthPole") == [plugin]
    Supervisor.stop(plugin)
    assert Robotica.Registry.lookup(registry, "NorthPole") == []
  end
end
