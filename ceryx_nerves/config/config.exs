# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

config :elixir, :time_zone_database, Tzdata.TimeZoneDatabase

config :ceryx,
  config_file: "/etc/robotica/config-{hostname}.yaml"

config :robotica_plugins,
  config_file: "/etc/robotica/ui-{hostname}.yaml",
  config_common_file: "../config/common.yaml",
  timezone: "Australia/Melbourne",
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

# Customize non-Elixir parts of the firmware.  See
# https://hexdocs.pm/nerves/advanced-configuration.html for details.
config :nerves, :firmware, rootfs_overlay: "rootfs_overlay"

# Use shoehorn to start the main application. See the shoehorn
# docs for separating out critical OTP applications such as those
# involved with firmware updates.
config :shoehorn,
  init: [
    :nerves_runtime,
    :nerves_network,
    :nerves_time,
    :nerves_init_gadget,
    :lifx,
    {CeryxNerves.Application, :config, []},
    :robotica
  ],
  app: Mix.Project.config()[:app]

config :nerves_network,
  regulatory_domain: "AU"

config :nerves_network, :default,
  wlan0: [
    ssid: System.get_env("NERVES_NETWORK_SSID"),
    psk: System.get_env("NERVES_NETWORK_PSK"),
    key_mgmt: String.to_atom(System.get_env("NERVES_NETWORK_MGMT"))
  ],
  eth0: [
    ipv4_address_method: :dhcp
  ]

config :nerves_time, :servers, [
  "0.pool.ntp.org",
  "1.pool.ntp.org",
  "2.pool.ntp.org",
  "3.pool.ntp.org"
]

config :nerves_firmware_ssh,
  authorized_keys: [
    "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAo9J3VtrQldIJeQR6ilEHLiYdOEOlanfKghN/ZOhd1B/TDD94vWo7R+M3shJDkPGR8qjPCGDUSZSg8G1bzPhMyAaTgLejdRk9yPt5Z/QmDs6rYk/RHCEl+9GTQEjBVbaUH0oeMsIiB1sgBzCj4Wcfd8cJwuWjzWQdwgMwApwOEV2Gpg6ZWDzfNVoe7YwgLZVvPngZCXNWQJ/9HRzXPEi1Nz0Gc2zciZS8FkrqG4VsWkRH8KT/4AJm0PWz7aY+OqnOF9Fn6hBwpnB3LO+a0HEFEbPdCB9V5ORH+xj6smkf/TMmq16oCexGyX3vbnKfKrRS5Vv5oxkjpHQyvemmG6gc6Q== /home/brian/.ssh/id_rsa"
  ]

config :nerves_init_gadget,
  ifname: "wlan0",
  mdns_domain: :hostname,
  ssh_console_port: 22,
  address_method: :dhcp

config :logger,
  backends: [RingLogger],
  compile_time_purge_matching: [
    [level_lower_than: :info]
  ]

config :logger, RingLogger, max_size: 1000

import_config "robotica_face.exs"

# Import target specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
# Uncomment to use target specific configurations

import_config "#{Mix.Project.config()[:target]}.exs"
