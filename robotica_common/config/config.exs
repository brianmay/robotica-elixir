# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

# This configuration is loaded before any dependency and is restricted
# to this project. If another project depends on this project, this
# file won't be loaded nor affect the parent project. For this reason,
# if you want to provide default values for your application for
# third-party users, it should be done in your "mix.exs" file.

# You can configure your application as:
#
#     config :robotica_common, key: :value
#
# and access this configuration in your application as:
#
#     Application.get_env(:robotica_common, :key)
#
# You can also configure a third-party app:
#
#     config :logger, level: :info
#
config :elixir, :time_zone_database, Tzdata.TimeZoneDatabase

config :robotica_common,
  timezone: "Australia/Melbourne",
  build_date: System.get_env("BUILD_DATE"),
  vcs_ref: System.get_env("VCS_REF"),
  location: nil,
  compile_config_files: true,
  config_common_file: "../../local/config/common.yaml",
  map_types: []

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id],
  level: :info,
  compile_time_purge_matching: [
    [level_lower_than: :info]
  ]

# It is also possible to import configuration files, relative to this
# directory. For example, you can emulate configuration per environment
# by uncommenting the line below and defining dev.exs, test.exs and such.
# Configuration from the imported file will override the ones defined
# here (which is why it is important to import them last).
#
import_config "#{Mix.env()}.exs"
