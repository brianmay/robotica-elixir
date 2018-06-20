defmodule Robotica.Plugins do
  @spec execute(server :: pid, action :: map) :: nil
  def execute(server, action) do
    GenServer.cast(server, {:execute, action})
    nil
  end

  @spec wait(server :: pid) :: nil
  def wait(server) do
    GenServer.call(server, {:wait}, :infinity)
  end
end
