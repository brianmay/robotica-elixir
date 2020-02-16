# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

config :ceryx,
  config_file: "test/ceryx.yaml"

config :robotica_plugins,
  config_file: "../config/ui.yaml.sample",
  config_common_file: "../config/common.yaml.sample"
