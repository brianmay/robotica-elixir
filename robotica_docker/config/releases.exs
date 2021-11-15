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

config :robotica_face,
  oidc: %{
    discovery_document_uri: System.get_env("OIDC_DISCOVERY_URL"),
    client_id: System.get_env("OIDC_CLIENT_ID"),
    client_secret: System.get_env("OIDC_CLIENT_SECRET"),
    scope: System.get_env("OIDC_AUTH_SCOPE")
  }

port = String.to_integer(System.get_env("PORT") || "4000")
http_url = System.get_env("HTTP_URL")
http_uri = URI.parse(http_url)

config :robotica_face, RoboticaFaceWeb.Endpoint,
  http: [
    :inet6,
    port: port,
    protocol_options: [max_header_value_length: 8096]
  ],
  url: [scheme: http_uri.scheme, host: http_uri.host, port: http_uri.port],
  secret_key_base: System.get_env("SECRET_KEY_BASE"),
  live_view: [
    signing_salt: System.get_env("SIGNING_SALT")
  ]

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
