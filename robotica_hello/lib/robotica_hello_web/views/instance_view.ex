defmodule RoboticaHelloWeb.InstanceView do
  use RoboticaHelloWeb, :view

  defp create_token(user) do
    {:ok, token, _claims} =
      RoboticaHello.Token.generate_and_sign(%{name: user.name, location: user.location})

    token
  end
end
