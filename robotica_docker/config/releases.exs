import Config

config :robotica_common,
  hostname: System.get_env("HOSTNAME"),
  config_common_file: System.get_env("ROBOTICA_COMMON_CONFIG")

config :robotica,
  hostname: System.get_env("HOSTNAME"),
  config_file: System.get_env("ROBOTICA_CONFIG"),
  classifications_file: System.get_env("ROBOTICA_CLASSIFICATIONS"),
  schedule_file: System.get_env("ROBOTICA_SCHEDULE"),
  sequences_file: System.get_env("ROBOTICA_SEQUENCES"),
  scenes_file: System.get_env("ROBOTICA_SCENES")

config :libcluster,
  topologies: [
    k8s: [
      strategy: Elixir.Cluster.Strategy.Kubernetes,
      config: [
        mode: :dns,
        kubernetes_node_basename: "robotica_docker",
        kubernetes_selector: System.get_env("KUBERNETES_SELECTOR"),
        kubernetes_namespace: System.get_env("NAMESPACE"),
        polling_interval: 10_000
      ]
    ]
  ]

config :plugoid,
  auth_cookie_store_opts: [
    signing_salt: System.get_env("SIGNING_SALT")
  ],
  state_cookie_store_opts: [
    signing_salt: System.get_env("SIGNING_SALT")
  ]
