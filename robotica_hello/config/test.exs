use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :robotica_hello, RoboticaHelloWeb.Endpoint,
  http: [port: 4002],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

config :robotica_hello,
  config_file: "../config/hello.yaml.sample"

config :robotica_hello, RoboticaHello.Repo,
  pool: Ecto.Adapters.SQL.Sandbox,
  url: System.get_env("DATABASE_URL_TEST")

config :robotica_hello, RoboticaHello.Accounts.Guardian,
  issuer: "robotica_hello",
  secret_key: "/q7S9SP028A/BbWqkiisc5qZXbBWQFg8+GSTkflTAfRw/K9jCzJKWpSWvWUEoUU4"

config :robotica_hello, RoboticaHelloWeb.Endpoint,
  secret_key_base: "oOWDT+7p6JENufDeyMQFLqDMsj1bkVfQT4Navmr5qYem9crHED4jAMr0Stf4aRNt"
