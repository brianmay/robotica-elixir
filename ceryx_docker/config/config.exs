# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

import_config "../../ceryx/config/config.exs"

import_config "../../robotica_face/config/common.exs"

import_config "../../robotica_common/config/docker.exs"

case Mix.env() do
  :prod ->
    config :ceryx,
      config_file: nil

  :dev ->
    nil

  :test ->
    nil
end
