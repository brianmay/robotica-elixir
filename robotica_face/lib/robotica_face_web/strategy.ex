defmodule RoboticaFaceWeb.Strategy do
  use JokenJwks.DefaultStrategyTemplate

  def init_opts(opts) do
    url = "https://www.googleapis.com/oauth2/v3/certs"
    Keyword.merge(opts, jwks_url: url)
  end
end
