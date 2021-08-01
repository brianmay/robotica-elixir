defmodule RoboticaHelloWeb.Plug.Auth do
  @moduledoc "Guardian authentication pipeline"

  defmodule IgnoreError do
    @moduledoc false

    import Plug.Conn
    use RoboticaHelloWeb, :controller

    @behaviour Guardian.Plug.ErrorHandler

    @impl Guardian.Plug.ErrorHandler
    def auth_error(conn, {_type, _reason}, _opts) do
      conn
      |> put_flash(:danger, "Error validating token")
    end
  end

  defmodule ErrorHandler do
    @moduledoc false

    import Plug.Conn
    use RoboticaHelloWeb, :controller

    @behaviour Guardian.Plug.ErrorHandler

    @impl Guardian.Plug.ErrorHandler
    def auth_error(conn, {_type, _reason}, _opts) do
      conn
      |> put_flash(:danger, "You are not authorised to access that page")
      |> redirect(to: Routes.session_path(conn, :new, next: current_path(conn)))
    end
  end

  use Guardian.Plug.Pipeline,
    otp_app: :robotica_hello,
    error_handler: ErrorHandler,
    module: RoboticaHello.Accounts.Guardian

  # If there is a session token, restrict it to an access token and validate it
  plug Guardian.Plug.VerifySession,
    claims: %{"typ" => "access"},
    error_handler: IgnoreError,
    halt: false

  # If there is an authorization header, restrict it to an access token and validate it
  plug Guardian.Plug.VerifyHeader, claims: %{"typ" => "access"}
  # Load the user if either of the verifications worked
  plug Guardian.Plug.LoadResource, allow_blank: true
end
