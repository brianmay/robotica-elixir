use Mix.Config

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
    {RoboticaNerves.Application, :config, []},
    :robotica_common,
    :robotica,
    :robotica_face,
    :robotica_ui
  ],
  app: Mix.Project.config()[:app]

config :nerves_network,
  regulatory_domain: "AU"

config :nerves_network, :default,
  wlan0: [
    ssid: System.get_env("NERVES_NETWORK_SSID"),
    psk: System.get_env("NERVES_NETWORK_PSK"),
    key_mgmt: String.to_atom(System.get_env("NERVES_NETWORK_MGMT") || "WPA-PSK")
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
  level: :info,
  compile_time_purge_matching: [
    [level_lower_than: :info]
  ]

config :logger, RingLogger, max_size: 1000

if Mix.Project.config()[:target] != "host" do
  config :tzdata, :data_dir, "/root/elixir_tzdata_data"
end
