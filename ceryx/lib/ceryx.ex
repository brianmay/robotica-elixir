defmodule Ceryx do
  @moduledoc """
  Main entry point for Ceryx
  """

  use Application
  require Ceryx.Config

  def start(_type, _args) do
    config = Ceryx.Config.configuration()
    Ceryx.Supervisor.start_link(config)
  end
end
