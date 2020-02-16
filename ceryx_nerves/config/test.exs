use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :robotica_face, RoboticaFaceWeb.Endpoint,
  http: [port: 4002],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

config :robotica_face, RoboticaFace.Repo,
  pool: Ecto.Adapters.SQL.Sandbox,
  url: System.get_env("DATABASE_URL_TEST")
