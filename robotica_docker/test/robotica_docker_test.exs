defmodule RoboticaDockerTest do
  use ExUnit.Case
  doctest RoboticaDocker

  test "greets the world" do
    assert RoboticaDocker.hello() == :world
  end
end
