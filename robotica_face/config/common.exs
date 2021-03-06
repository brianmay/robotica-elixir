# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

port = String.to_integer(System.get_env("PORT") || "4000")

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
  http: [port: port, ip: {0, 0, 0, 0, 0, 0, 0, 0}],
  url: [host: {:system, "HTTP_HOST"}],
  secret_key_base: System.get_env("SECRET_KEY_BASE"),
  render_errors: [view: RoboticaFaceWeb.ErrorView, accepts: ~w(html json)],
  pubsub_server: RoboticaFace.PubSub,
  live_view: [
    signing_salt: System.get_env("SIGNING_SALT")
  ],
  code_reloader: false,
  server: true

config :joken,
  login_secret: System.get_env("LOGIN_SECRET")

config :phoenix,
  json_library: Jason,
  template_engines: [leex: Phoenix.LiveView.Engine]

if System.get_env("IPV6") != nil do
  config :robotica_face, RoboticaFace.Repo, socket_options: [:inet6]
end

case Mix.env() do
  :dev ->
    config :robotica_face, RoboticaFaceWeb.Endpoint,
      debug_errors: true,
      code_reloader: true,
      check_origin: false,
      watchers: [
        node: [
          "node_modules/webpack/bin/webpack.js",
          "--mode",
          "development",
          "--watch",
          "--watch-options-stdin",
          cd: Path.expand("../../robotica_face/assets", __DIR__)
        ]
      ],
      live_reload: [
        patterns: [
          ~r{priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$},
          ~r{priv/gettext/.*(po)$},
          ~r{lib/robotica_face_web/views/[a-z].*(ex)$},
          ~r{lib/robotica_face_web/templates/[a-z].*(eex)$},
          ~r{lib/robotica_face_web/live/[a-z].*(ex)$}
        ]
      ]

    config :phoenix_live_reload,
      dirs: ["../robotica_face"]

    config :phoenix, :stacktrace_depth, 20
    config :phoenix, :plug_init_mode, :runtime

  :test ->
    config :robotica_face, RoboticaFaceWeb.Endpoint,
      http: [port: 4002],
      url: [host: "localhost"],
      secret_key_base: "dumL2k9lDFzSg+OuQrpbQqkYZ22NnlmRLS/IEpGtu8d+3mofjYRjTjkyUg/r9hf1",
      live_view: [
        signing_salt: "dumL2k9lDFzSg+OuQrpbQqkYZ22NnlmRLS/IEpGtu8d+3mofjYRjTjkyUg/r9hf1"
      ],
      server: false

    config :robotica_face,
      api_username: "google username",
      api_password: "google pqassword",
      mqtt_host: "mqtt.example.org",
      mqtt_port: 8883,
      ca_cert_file: "cacert_dummy.pem",
      mqtt_user_name: "mqtt_username",
      mqtt_password: "mqtt_password"

    config :joken,
      login_secret: "lXI0Bt7DrB968JJ9Vc+q14JD1vK3S1VrmKXLNVJJ7rObkGEULZLdfwqo/NSyb8ez"

  :prod ->
    config :robotica_face, RoboticaFaceWeb.Endpoint,
      cache_static_manifest: "priv/static/cache_manifest.json",
      server: true,
      root: ".",
      version: Application.spec(:robotica_face, :vsn)
end
