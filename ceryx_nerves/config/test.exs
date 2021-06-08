use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :robotica_face, RoboticaFaceWeb.Endpoint,
  http: [port: 4002],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

config :ceryx,
  config_file: "test/config.yaml"

config :robotica_common,
  config_common_file: "../config/common.yaml.sample"
