use Mix.Config

# Configure your database
config :robotica_hello, RoboticaHello.Repo,
  username: "postgres",
  password: "postgres",
  database: "robotica_hello_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :robotica_hello, RoboticaHelloWeb.Endpoint,
  http: [port: 4002],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn
