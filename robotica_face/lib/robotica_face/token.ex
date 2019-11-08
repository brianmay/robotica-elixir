defmodule RoboticaFace.Token do
  use Joken.Config, default_signer: :login_secret

  @impl true
  def token_config do
    default_claims(
      iss: "https://robotica.linuxpenguins.xyz",
      aud: "all@robotica.linuxpenguins.xyz",
      default_exp: 60 * 60 * 24 * 365
    )
  end
end
