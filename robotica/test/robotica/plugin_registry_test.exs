defmodule Robotica.PluginRegistry.Test do
  use ExUnit.Case, async: true

  setup do
    start_supervised!({Robotica.DummySubscriptions, name: Robotica.Subscriptions})
    registry = start_supervised!({Robotica.PluginRegistry, name: Robotica.PluginRegistry})
    %{registry: registry}
  end

  test "lookup location", %{registry: _registry} do
    assert Robotica.PluginRegistry.lookup(["NorthPole"], []) == []
    assert Robotica.PluginRegistry.lookup(["NorthPole"], ["Santa"]) == []
    assert Robotica.PluginRegistry.lookup(["NorthPole"], ["Santa", "Easter Bunny"]) == []
  end

  test "add plugin to location", %{registry: _registry} do
    config = %Robotica.Plugins.Logging.Config{}

    plugin = %Robotica.Plugin{
      module: Robotica.Plugins.Logging,
      location: "SouthPole",
      device: "Santa",
      config: config
    }

    {:ok, pid} = start_supervised({plugin.module, plugin})
    assert [] = Robotica.PluginRegistry.lookup(["SouthPole"], [])
    assert [^pid] = Robotica.PluginRegistry.lookup(["SouthPole"], nil)
    assert [^pid] = Robotica.PluginRegistry.lookup(["SouthPole"], ["Santa"])
    assert [^pid] = Robotica.PluginRegistry.lookup(["SouthPole"], ["Santa", "Easter Bunny"])
  end

  test "stops plugin on exit", %{registry: _registry} do
    config = %Robotica.Plugins.Logging.Config{}

    plugin = %Robotica.Plugin{
      module: Robotica.Plugins.Logging,
      location: "SouthPole",
      device: "Santa",
      config: config
    }

    {:ok, pid} = start_supervised({plugin.module, plugin})
    assert [^pid] = Robotica.PluginRegistry.lookup(["SouthPole"], nil)

    stop_supervised(plugin.module)
    assert [] = Robotica.PluginRegistry.lookup(["SouthPole"], nil)
  end
end
