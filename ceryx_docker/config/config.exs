# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

config :elixir, :time_zone_database, Tzdata.TimeZoneDatabase

config :ceryx,
  config_file: nil

config :robotica_face,
  api_username: "google_username",
  api_password: "google_password",
  mqtt_host: "mqtt.example.org",
  mqtt_port: 8883,
  ca_cert_file: "certificate",
  mqtt_user_name: "mqtt_user_name",
  mqtt_password: "mqtt_password"

config :robotica_common,
  build_date: System.get_env("BUILD_DATE"),
  vcs_ref: System.get_env("VCS_REF"),
  config_common_file: nil,
  timezone: "Australia/Melbourne",
  map_types: [
    {Robotica.Plugin, {Robotica.Validation, :validate_plugin_config}}
  ]

import_config "robotica_face.exs"

# Import target specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
# Uncomment to use target specific configurations

import_config "#{Mix.env()}.exs"
