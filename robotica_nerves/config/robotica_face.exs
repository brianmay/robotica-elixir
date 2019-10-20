# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :robotica_face,
  api_username: System.get_env("GOOGLE_USERNAME"),
  api_password: System.get_env("GOOGLE_PASSWORD"),
  mqtt_host: System.get_env("MQTT_HOST"),
  mqtt_port: String.to_integer(System.get_env("MQTT_PORT") || "8883"),
  ca_cert_file: System.get_env("CA_CERT_FILE"),
  mqtt_user_name: System.get_env("MQTT_USER_NAME"),
  mqtt_password: System.get_env("MQTT_PASSWORD")

# Configures the endpoint
config :robotica_face, RoboticaFaceWeb.Endpoint,
  http: [port: 4000, ip: {0, 0, 0, 0, 0, 0, 0, 0}],
  url: [host: {:system, "HOST"}],
  secret_key_base: System.get_env("SECRET_KEY_BASE"),
  render_errors: [view: RoboticaFaceWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: RoboticaFace.PubSub, adapter: Phoenix.PubSub.PG2],
  live_view: [
    signing_salt: System.get_env("SIGNING_SALT")
  ],
  code_reloader: false,
  server: true

config :joken,
  login_secret: System.get_env("LOGIN_SECRET")

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

if System.get_env("IPV6") != nil do
  config :robotica_face, RoboticaFace.Repo, socket_options: [:inet6]
end

case Mix.env() do
  :dev ->
    nil

  :test ->
    config :robotica_face, RoboticaFaceWeb.Endpoint,
      http: [port: 4002],
      server: false

  :prod ->
    config :robotica_face, RoboticaFaceWeb.Endpoint,
      cache_static_manifest: "priv/static/cache_manifest.json",
      server: true,
      root: ".",
      version: Application.spec(:robotica_face, :vsn)
end
