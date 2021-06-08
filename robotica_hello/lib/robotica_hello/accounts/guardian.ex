defmodule RoboticaHello.Accounts.Guardian do
  @moduledoc """
  Guardian resource claims module
  """

  use Guardian, otp_app: :robotica_hello

  alias RoboticaHello.Accounts

  def subject_for_token(user, _claims) do
    {:ok, to_string(user.id)}
  end

  def resource_from_claims(%{"sub" => id}) do
    case Accounts.get_user!(id) do
      nil -> {:error, :resource_not_found}
      user -> {:ok, user}
    end
  end
end
