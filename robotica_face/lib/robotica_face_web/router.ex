defmodule RoboticaFaceWeb.Router do
  use RoboticaFaceWeb, :router

  @api_username Application.get_env(:robotica_face, :api_username)
  @api_password Application.get_env(:robotica_face, :api_password)

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

  pipeline :api do
    plug :accepts, ["json"]
    plug BasicAuth, username: @api_username, password: @api_password
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
    get "/remote", PageController, :remote
    get "/schedule", PageController, :schedule
    get "/tesla", PageController, :tesla
  end

  scope "/api", RoboticaFaceWeb do
    pipe_through :api

    post "/", ApiController, :index
  end
end
