defmodule RoboticaHelloWeb.InstanceView do
  use RoboticaHelloWeb, :view

  alias RoboticaHello.Accounts.User

  @spec create_token(User.t()) :: String.t()
  defp create_token(%User{} = user) do
    {:ok, token, _claims} =
      RoboticaHello.Token.generate_and_sign(%{"name" => user.name, "location" => user.location})

    token
  end
end
