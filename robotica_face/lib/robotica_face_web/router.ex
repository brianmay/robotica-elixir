defmodule RoboticaFaceWeb.Router do
  use RoboticaFaceWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
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

  scope "/", RoboticaFaceWeb do
    pipe_through :browser
    pipe_through :csrf
    pipe_through :auth
    pipe_through :ensure_auth

    get "/local", PageController, :local
    get "/schedule", PageController, :schedule
  end
end
