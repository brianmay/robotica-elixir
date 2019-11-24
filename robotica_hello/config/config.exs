# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :robotica_hello,
  ecto_repos: [RoboticaHello.Repo]

config :robotica_hello, RoboticaHello.Repo,
  url: System.get_env("DATABASE_URL"),
  pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10")

# Configures the endpoint
config :robotica_hello, RoboticaHelloWeb.Endpoint,
  http: [:inet6, port: String.to_integer(System.get_env("PORT") || "4000")],
  url: [host: "localhost"],
  secret_key_base: System.get_env("SECRET_KEY_BASE"),
  render_errors: [view: RoboticaHelloWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: RoboticaHello.PubSub, adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :robotica_hello, RoboticaHello.Users.Guardian,
  issuer: "robotica_hello",
  secret_key: System.get_env("GUARDIAN_SECRET")

config :joken,
  login_secret: System.get_env("LOGIN_SECRET")

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
