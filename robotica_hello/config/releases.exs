import Config

config :phone_Hello, RoboticaHello.Repo,
  url: System.get_env("DATABASE_URL"),
  pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10")

# Configures the endpoint
config :robotica_hello, RoboticaHelloWeb.Endpoint,
  http: [:inet6, port: String.to_integer(System.get_env("PORT") || "4000")],
  url: [host: System.get_env("HOST"), port: port],
  secret_key_base: System.get_env("SECRET_KEY_BASE")

config :robotica_hello, RoboticaHello.Users.Guardian,
  issuer: "robotica_hello",
  secret_key: System.get_env("GUARDIAN_SECRET")

config :joken,
  login_secret: System.get_env("LOGIN_SECRET")
