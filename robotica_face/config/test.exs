use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :robotica_face, RoboticaFaceWeb.Endpoint,
  http: [port: 4002],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

config :robotica_face,
  api_username: "google_username",
  api_password: "google_password",
  mqtt_host: "mqtt.example.org",
  mqtt_port: 8883,
  ca_cert_file: "certificate",
  mqtt_user_name: "mqtt_user_name",
  mqtt_password: "mqtt_password"

config :robotica_face, RoboticaFaceWeb.Endpoint,
  secret_key_base: "oOWDT+7p6JENufDeyMQFLqDMsj1bkVfQT4Navmr5qYem9crHED4jAMr0Stf4aRNt",
  live_view: [
    signing_salt: "lFJrL13YHIH/wScmyEG7U2hXsoNqxSJB"
  ]
