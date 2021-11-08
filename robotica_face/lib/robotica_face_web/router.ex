defmodule RoboticaFaceWeb.Router do
  use RoboticaFaceWeb, :router

  use Plugoid.RedirectURI,
    token_callback: &RoboticaFaceWeb.TokenCallback.callback/5

  import Phoenix.LiveDashboard.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {RoboticaFaceWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :csrf do
    plug :protect_from_forgery
  end

  defmodule PlugoidConfig do
    def common do
      config = Application.get_env(:robotica_face, :oidc)

      [
        issuer: config.discovery_document_uri,
        client_id: config.client_id,
        scope: String.split(config.scope, " "),
        client_config: RoboticaFaceWeb.ClientCallback
      ]
    end
  end

  pipeline :auth do
    plug Replug,
      plug: {Plugoid, on_unauthenticated: :pass},
      opts: {PlugoidConfig, :common}
  end

  pipeline :ensure_auth do
    plug Replug,
      plug: {Plugoid, on_unauthenticated: :auth},
      opts: {PlugoidConfig, :common}
  end

  pipeline :ensure_admin do
    plug RoboticaFaceWeb.Plug.CheckAdmin
  end

  live_session :default, on_mount: RoboticaFaceWeb.InitAssigns do
    scope "/", RoboticaFaceWeb do
      pipe_through :browser
      pipe_through :csrf
      pipe_through :auth

      get "/", PageController, :index
      post "/logout", PageController, :logout
    end

    scope "/", RoboticaFaceWeb do
      pipe_through :browser
      pipe_through :csrf
      pipe_through :ensure_auth

      get "/login", PageController, :login
      live "/local", Live.Local, :local
      live "/local/:location", Live.Local, :local
      live "/schedule", Live.Schedule, :schedule
    end
  end

  scope "/", RoboticaFaceWeb do
    pipe_through :browser
    pipe_through :csrf
    pipe_through :ensure_auth
    pipe_through :ensure_admin

    live_dashboard "/dashboard", metrics: RoboticaFaceWeb.Telemetry
  end
end
