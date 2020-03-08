defmodule CeryxDockerTest do
  use ExUnit.Case
  doctest CeryxDocker

  test "greets the world" do
    assert CeryxDocker.hello() == :world
  end
end
