defmodule RoboticaFaceWeb.Token do
  use Joken.Config

  add_hook(JokenJwks, strategy: RoboticaFaceWeb.Strategy)

  @impl true
  def token_config do
    default_claims(
      iss: "https://accounts.google.com",
      aud: "974679897892-90sb59k5o462lk2c7i7t3n7ir30gal67.apps.googleusercontent.com"
    )
  end
end
