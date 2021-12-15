# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Config

import_config "../../robotica/config/config.exs"

import_config "../../robotica_face/config/common.exs"

import_config "../../robotica_common/config/docker.exs"

config :libcluster,
  topologies: []
