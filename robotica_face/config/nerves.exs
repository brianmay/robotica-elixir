import Config

if Mix.Project.config()[:target] != "host" do
  config :robotica_face, RoboticaFaceWeb.Endpoint,
    force_ssl: [hsts: true],
    https: [
      port: 443,
      ip: {0, 0, 0, 0, 0, 0, 0, 0},
      otp_app: :robotica_nerves,
      keyfile: "priv/key.pem",
      certfile: "priv/cert.pem",
      # OPTIONAL Key for intermediate certificates
      cacertfile: "priv/cacert.pem"
    ]
end
