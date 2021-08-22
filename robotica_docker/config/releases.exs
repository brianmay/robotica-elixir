import Config

config :robotica_common,
  hostname: System.get_env("HTTP_HOST"),
  config_common_file: System.get_env("ROBOTICA_COMMON_CONFIG")

config :robotica,
  hostname: System.get_env("HTTP_HOST"),
  config_file: System.get_env("ROBOTICA_CONFIG"),
  classifications_file: System.get_env("ROBOTICA_CLASSIFICATIONS"),
  schedule_file: System.get_env("ROBOTICA_SCHEDULE"),
  sequences_file: System.get_env("ROBOTICA_SEQUENCES"),
  scenes_file: System.get_env("ROBOTICA_SCENES")

port = String.to_integer(System.get_env("PORT") || "4000")

config :robotica_face, RoboticaFaceWeb.Endpoint,
  http: [:inet6, port: port],
  url: [host: System.get_env("HTTP_HOST")],
  secret_key_base: System.get_env("SECRET_KEY_BASE"),
  live_view: [
    signing_salt: System.get_env("SIGNING_SALT")
  ]

config :joken,
  login_secret: System.get_env("LOGIN_SECRET")

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
