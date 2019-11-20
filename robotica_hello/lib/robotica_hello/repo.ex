defmodule RoboticaHello.Repo do
  use Ecto.Repo,
    otp_app: :robotica_hello,
    adapter: Ecto.Adapters.Postgres
end
