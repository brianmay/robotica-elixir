defmodule RoboticaNerves.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  @target Mix.Project.config()[:target]

  use Application
  require Logger

  defp cmd(command, args) do
    Logger.debug("Executing #{command} #{Enum.join(args, " ")}")
    {_, rc} = System.cmd(command, args)
    Logger.debug("---> #{rc}")
    rc
  end

  def config do
    Logger.info("Configuring user level...")

    if not File.exists?("/root/mpd") do
      File.mkdir!("/root/mpd")
      File.mkdir!("/root/mpd/music")
      File.mkdir!("/root/mpd/playlists")
    end

    Logger.debug("Starting mpd.")

    case cmd("mpd", []) do
      0 ->
        nil

      _ ->
        Process.sleep(2000)
        Logger.debug("Retrying mpd.")
        0 = cmd("mpd", [])
    end

    System.put_env("HTTP_URL", Robotica.Config.http_url())
    Logger.info("...done.")
  end

  def start(_type, _args) do
    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: RoboticaNerves.Supervisor]
    Supervisor.start_link(children(@target), opts)
  end

  # List all child processes to be supervised
  def children("host") do
    [
      # Starts a worker by calling: RoboticaNerves.Worker.start_link(arg)
      # {RoboticaNerves.Worker, arg},
    ]
  end

  def children(_target) do
    [
      # Starts a worker by calling: RoboticaNerves.Worker.start_link(arg)
      # {RoboticaNerves.Worker, arg},
    ]
  end
end
