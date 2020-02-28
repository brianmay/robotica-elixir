# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

config :robotica,
  config_file: "test/config.yaml",
  classifications_file: "test/classifications.yaml",
  schedule_file: "test/schedule.yaml",
  sequences_file: "test/sequences.yaml",
  timezone: "Australia/Melbourne"

config :robotica_plugins,
  config_common_file: "../config/common.yaml.sample"
