defmodule RoboticaFaceWeb.Router do
  use RoboticaFaceWeb, :router
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

  pipeline :auth do
    plug RoboticaFace.Auth.CheckLoginToken
  end

  pipeline :ensure_auth do
    plug RoboticaFace.Auth.EnsureAuth
  end

  scope "/", RoboticaFaceWeb do
    pipe_through :browser
    pipe_through :auth

    post "/login", SessionController, :login
  end

  scope "/", RoboticaFaceWeb do
    pipe_through :browser
    pipe_through :csrf
    pipe_through :auth

    get "/", PageController, :index
    get "/login", SessionController, :index
    post "/logout", SessionController, :logout
  end

  scope "/", RoboticaFaceWeb.Live do
    pipe_through :browser
    pipe_through :csrf
    pipe_through :auth
    pipe_through :ensure_auth

    live "/local", Local, :local
    live "/local/:location", Local, :local
    live "/schedule", Schedule, :schedule

    if Mix.env() == :dev do
      live_dashboard "/dashboard", metrics: RoboticaFaceWeb.Telemetry
    end
  end
end
