defmodule RoboticaDocker.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    topologies = Application.get_env(:libcluster, :topologies)

    # List all child processes to be supervised
    children = [
      {Cluster.Supervisor, [topologies, [name: RoboticaDocker.ClusterSupervisor]]}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: RoboticaDocker.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
