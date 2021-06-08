defmodule RoboticaHello.Token do
  @moduledoc """
  Define tokens for robotica logins
  """
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
