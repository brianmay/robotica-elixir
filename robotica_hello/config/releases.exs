import Config

config :robotica_common,
  config_common_file: nil

port = String.to_integer(System.get_env("PORT") || "4000")

config :robotica_hello,
  config_file: System.get_env("ROBOTICA_HELLO_CONFIG")

config :robotica_hello, RoboticaHello.Repo,
  url: System.get_env("DATABASE_URL"),
  pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10")

config :robotica_hello, RoboticaHelloWeb.Endpoint,
  http: [:inet6, port: port],
  url: [host: System.get_env("HTTP_HOST")],
  secret_key_base: System.get_env("SECRET_KEY_BASE")

config :robotica_hello, RoboticaHello.Accounts.Guardian,
  issuer: "robotica_hello",
  secret_key: System.get_env("GUARDIAN_SECRET")

config :joken,
  login_secret: System.get_env("LOGIN_SECRET")
