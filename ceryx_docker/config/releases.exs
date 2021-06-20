import Config

config :robotica_common,
  config_common_file: System.get_env("ROBOTICA_COMMON_CONFIG")

port = String.to_integer(System.get_env("PORT") || "4000")

config :robotica_face, RoboticaFaceWeb.Endpoint,
  http: [:inet6, port: port],
  url: [host: System.get_env("HTTP_HOST")],
  secret_key_base: System.get_env("SECRET_KEY_BASE"),
  live_view: [
    signing_salt: System.get_env("SIGNING_SALT")
  ]

config :joken,
  login_secret: System.get_env("LOGIN_SECRET")
