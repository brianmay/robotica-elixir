defmodule RoboticaFaceWeb.ClientCallback do
  @moduledoc """
  Implement OIDC client config
  """

  @behaviour OIDC.ClientConfig
  @impl true
  def get(_client_id) do
    config = Application.get_env(:robotica_face, :oidc)

    %{
      "client_id" => config.client_id,
      "client_secret" => config.client_secret
    }
  end
end
