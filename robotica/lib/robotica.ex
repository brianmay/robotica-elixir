defmodule Robotica do
  @moduledoc """
  Top level entry point
  """

  use Application
  require Robotica.Config

  def start(_type, _args) do
    config = Robotica.Config.configuration()
    Robotica.Supervisor.start_link(config)
  end
end
