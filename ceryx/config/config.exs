# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

import_config "../../robotica_common/config/config.exs"

config :ceryx,
  config_file: "../../local/config/ceryx.yaml"

case Mix.env() do
  :test ->
    config :ceryx,
      config_file: "../test/ceryx.yaml"

  :dev ->
    nil

  :prod ->
    nil
end
