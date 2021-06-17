use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :robotica_face, RoboticaFaceWeb.Endpoint,
  http: [port: 4002],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

config :robotica,
  config_file: "test/config.yaml",
  classifications_file: "test/classifications.yaml",
  schedule_file: "test/schedule.yaml",
  sequences_file: "test/sequences.yaml",
  scenes_file: "test/scenes.yaml",
  timezone: "Australia/Melbourne",
  hostname: "test-host"

config :robotica_face,
  api_username: "google_username",
  api_password: "google_password",
  mqtt_host: "mqtt.example.org",
  mqtt_port: 8883,
  ca_cert_file: "certificate",
  mqtt_user_name: "mqtt_user_name",
  mqtt_password: "mqtt_password"

config :robotica_common,
  config_common_file: "../config/common.yaml.sample"
