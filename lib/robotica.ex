defmodule Robotica do
  use Application
  require Robotica.Config

  def start(_type, _args) do
    config = Robotica.Config.configuration()
    Robotica.Supervisor.start_link(config)
  end
end
