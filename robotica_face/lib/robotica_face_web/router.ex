defmodule RoboticaFaceWeb.Router do
  use RoboticaFaceWeb, :router

  @api_username Application.get_env(:robotica_face, :api_username)
  @api_password Application.get_env(:robotica_face, :api_password)

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug Phoenix.LiveView.Flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
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

    get "/", PageController, :index
    get "/login", SessionController, :index
    post "/login", SessionController, :login
    post "/logout", SessionController, :logout
  end

  scope "/", RoboticaFaceWeb do
    pipe_through :browser
    pipe_through :auth
    pipe_through :ensure_auth

    scope "/schedule" do
      get "/", ScheduleController, :upcoming_list
    end
  end

  scope "/api", RoboticaFaceWeb do
    pipe_through :api

    post "/", ApiController, :index
  end
end
