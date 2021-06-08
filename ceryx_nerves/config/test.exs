use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :robotica_face, RoboticaFaceWeb.Endpoint,
  http: [port: 4002],
  server: false

config :ceryx,
  config_file: "../config/ceryx.yaml.sample"

config :robotica_common,
  config_common_file: "../config/common.yaml.sample"

# Print only warnings and errors during test
config :logger, level: :warn
