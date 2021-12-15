# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
use Config

import_config "../../robotica_common/config/config.exs"

config :robotica,
  config_file: "../../local/config/config.yaml",
  classifications_file: "../../local/config/classifications.yaml",
  schedule_file: "../../local/config/schedule.yaml",
  sequences_file: "../../local/config/sequences.yaml",
  scenes_file: "../../local/config/scenes.yaml",
  timezone: "Australia/Melbourne"

config :robotica_common,
  map_types: [
    {Robotica.Plugin, {Robotica.Validation, :validate_plugin_config}}
  ]

config :lifx,
  tcp_server: false,
  tcp_port: 8800,
  multicast: {192, 168, 5, 255},
  #  Don't make this too small or the poller task will fall behind.
  dead_time: 55 * 1000,
  poll_discover_time: 10 * 1000,
  # Should be at least max_retries*wait_between_retry.
  max_api_timeout: 5000,
  max_retries: 3,
  wait_between_retry: 500,
  udp: Lifx.Udp

config :tp_link_hs100,
  multicast: "192.168.5.255",
  dead_time: 35 * 1000,
  poll_discover_time: 10 * 1000,
  wait_time: 1 * 1000

case Mix.env() do
  :test ->
    config :robotica,
      hostname: "test-host",
      config_file: "../test/config.yaml",
      classifications_file: "../test/classifications.yaml",
      schedule_file: "../test/schedule.yaml",
      sequences_file: "../test/sequences.yaml",
      scenes_file: "../test/scenes.yaml",
      timezone: "Australia/Melbourne"

  :dev ->
    nil

  :prod ->
    nil
end
