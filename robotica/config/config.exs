# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

config :elixir, :time_zone_database, Tzdata.TimeZoneDatabase

config :robotica,
  config_file: "../config/config.yaml",
  classifications_file: "../config/classifications.yaml",
  schedule_file: "../config/schedule.yaml",
  sequences_file: "../config/sequences.yaml",
  timezone: "Australia/Melbourne"

config :robotica_plugins,
  location: nil,
  config_common_file: "../config/common.yaml",
  map_types: [
    {Robotica.Plugin, {Robotica.Validation, :validate_plugin_config}}
  ]

config :lifx,
  tcp_server: false,
  tcp_port: 8800,
  multicast: {192, 168, 5, 255},
  #  Don't make this too small or the poller task will fall behind.
  poll_state_time: 10 * 60 * 1000,
  poll_discover_time: 1 * 60 * 1000,
  # Should be at least max_retries*wait_between_retry.
  max_api_timeout: 5000,
  max_retries: 3,
  wait_between_retry: 500,
  udp: Lifx.Udp

config :logger,
  backends: [:console],
  compile_time_purge_matching: [
    [level_lower_than: :info]
  ]

# This configuration is loaded before any dependency and is restricted
# to this project. If another project depends on this project, this
# file won't be loaded nor affect the parent project. For this reason,
# if you want to provide default values for your application for
# 3rd-party users, it should be done in your "mix.exs" file.

# You can configure your application as:
#
#     config :robotica, key: :value
#
# and access this configuration in your application as:
#
#     Application.get_env(:robotica, :key)
#
# You can also configure a 3rd-party app:
#
#     config :logger, level: :info
#

# It is also possible to import configuration files, relative to this
# directory. For example, you can emulate configuration per environment
# by uncommenting the line below and defining dev.exs, test.exs and such.
# Configuration from the imported file will override the ones defined
# here (which is why it is important to import them last).

import_config "#{Mix.env()}.exs"
