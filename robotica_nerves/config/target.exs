import Config

config :nerves_time, :servers, [
  "0.pool.ntp.org",
  "1.pool.ntp.org",
  "2.pool.ntp.org",
  "3.pool.ntp.org"
]

# Use shoehorn to start the main application. See the shoehorn
# docs for separating out critical OTP applications such as those
# involved with firmware updates.

config :shoehorn,
  init: [
    :nerves_runtime,
    :nerves_pack,
    :lifx,
    {RoboticaNerves.Application, :config, []},
    :robotica_common,
    :robotica,
    :robotica_face,
    :robotica_ui
  ],
  app: Mix.Project.config()[:app]

# Nerves Runtime can enumerate hardware devices and send notifications via
# SystemRegistry. This slows down startup and not many programs make use of
# this feature.

config :nerves_runtime, :kernel, use_system_registry: false

# Erlinit can be configured without a rootfs_overlay. See
# https://github.com/nerves-project/erlinit/ for more information on
# configuring erlinit.

config :nerves,
  erlinit: [
    hostname_pattern: "nerves-%s"
  ]

# Configure the device for SSH IEx prompt access and firmware updates
#
# * See https://hexdocs.pm/nerves_ssh/readme.html for general SSH configuration
# * See https://hexdocs.pm/ssh_subsystem_fwup/readme.html for firmware updates

config :nerves_ssh,
  authorized_keys: [
    "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAo9J3VtrQldIJeQR6ilEHLiYdOEOlanfKghN/ZOhd1B/TDD94vWo7R+M3shJDkPGR8qjPCGDUSZSg8G1bzPhMyAaTgLejdRk9yPt5Z/QmDs6rYk/RHCEl+9GTQEjBVbaUH0oeMsIiB1sgBzCj4Wcfd8cJwuWjzWQdwgMwApwOEV2Gpg6ZWDzfNVoe7YwgLZVvPngZCXNWQJ/9HRzXPEi1Nz0Gc2zciZS8FkrqG4VsWkRH8KT/4AJm0PWz7aY+OqnOF9Fn6hBwpnB3LO+a0HEFEbPdCB9V5ORH+xj6smkf/TMmq16oCexGyX3vbnKfKrRS5Vv5oxkjpHQyvemmG6gc6Q== /home/brian/.ssh/id_rsa"
  ]

# Configure the network using vintage_net
# See https://github.com/nerves-networking/vintage_net for more information
config :vintage_net,
  regulatory_domain: "AU",
  config: [
    {"usb0", %{type: VintageNetDirect}},
    {"eth0",
     %{
       type: VintageNetEthernet,
       ipv4: %{method: :dhcp}
     }},
    {"wlan0",
     %{
       type: VintageNetWiFi,
       vintage_net_wifi: %{
         networks: [
           %{
             key_mgmt: :wpa_psk,
             ssid: System.get_env("NERVES_NETWORK_SSID"),
             psk: System.get_env("NERVES_NETWORK_PSK")
           }
         ]
       },
       ipv4: %{method: :dhcp}
     }}
  ]

config :mdns_lite,
  # The `hosts` key specifies what hostnames mdns_lite advertises.  `:hostname`
  # advertises the device's hostname.local. For the official Nerves systems, this
  # is "nerves-<4 digit serial#>.local".  The `"nerves"` host causes mdns_lite
  # to advertise "nerves.local" for convenience. If more than one Nerves device
  # is on the network, it is recommended to delete "nerves" from the list
  # because otherwise any of the devices may respond to nerves.local leading to
  # unpredictable behavior.

  hosts: [:hostname, "nerves"],
  ttl: 120,

  # Advertise the following services over mDNS.
  services: [
    %{
      protocol: "ssh",
      transport: "tcp",
      port: 22
    },
    %{
      protocol: "sftp-ssh",
      transport: "tcp",
      port: 22
    },
    %{
      protocol: "epmd",
      transport: "tcp",
      port: 4369
    }
  ]

# Import target specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
# Uncomment to use target specific configurations

# import_config "#{Mix.target()}.exs"
