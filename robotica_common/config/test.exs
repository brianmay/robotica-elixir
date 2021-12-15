# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
import Config

config :robotica_common,
  hostname: "test-host",
  config_common_file: "../test/common.yaml",
  compile_config_files: false

config :logger, level: :warn
