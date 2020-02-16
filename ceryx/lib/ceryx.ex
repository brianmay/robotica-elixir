defmodule Ceryx do
  use Application
  require Ceryx.Config

  def start(_type, _args) do
    config = Ceryx.Config.configuration()
    Ceryx.Supervisor.start_link(config)
  end
end
