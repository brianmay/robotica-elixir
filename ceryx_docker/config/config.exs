# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

config :elixir, :time_zone_database, Tzdata.TimeZoneDatabase

config :ceryx,
  config_file: nil

config :robotica_common,
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
