use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :robotica_hello, RoboticaHelloWeb.Endpoint,
  http: [port: 4002],
  server: false

config :robotica_hello,
  ecto_repos: [RoboticaHello.Repo],
  config_file: "../config/hello.yaml.sample"

config :robotica_hello, RoboticaHello.Repo,
  pool: Ecto.Adapters.SQL.Sandbox,
  url: System.get_env("DATABASE_URL_TEST")

config :robotica_hello, RoboticaHelloWeb.Endpoint,
  secret_key_base: "oOWDT+7p6JENufDeyMQFLqDMsj1bkVfQT4Navmr5qYem9crHED4jAMr0Stf4aRNt"

config :robotica_hello, RoboticaHello.Accounts.Guardian,
  issuer: "robotica_hello",
  secret_key: "/q7S9SP028A/BbWqkiisc5qZXbBWQFg8+GSTkflTAfRw/K9jCzJKWpSWvWUEoUU4"

config :joken,
  login_secret: "yZYpztc9zI9E6xmfY47yfl6NCcvdk6h8ixk/SZv/3q5DshqH26bAD+K9r550mhGh"
