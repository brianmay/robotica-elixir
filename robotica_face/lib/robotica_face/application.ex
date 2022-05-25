defmodule RoboticaFace.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  require Logger

  def start(_type, _args) do
    # Kludge to set http url correctly for nerves at runtime
    http_url = System.get_env("HTTP_URL")

    if http_url != nil do
      Logger.debug("Setting url to '#{http_url}'.")
      http_uri = URI.parse(http_url)

      endpoint =
        Application.get_env(:robotica_face, RoboticaFaceWeb.Endpoint)
        |> Keyword.put(:url, scheme: http_uri.scheme, host: http_uri.host, port: http_uri.port)

      Application.put_env(:robotica_face, RoboticaFaceWeb.Endpoint, endpoint)
    end

    # List all child processes to be supervised
    children = [
      RoboticaFaceWeb.Telemetry,
      # Start the endpoint when the application starts
      RoboticaFaceWeb.Endpoint,
      {Phoenix.PubSub, [name: RoboticaFace.PubSub, adapter: Phoenix.PubSub.PG2]}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: RoboticaFace.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    RoboticaFaceWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
