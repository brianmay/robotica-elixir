defmodule RoboticaHelloWeb.Router do
  use RoboticaHelloWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :auth do
    plug RoboticaHelloWeb.Plug.Auth
  end

  # We use ensure_auth to fail if there is no one logged in
  pipeline :ensure_auth do
    plug Guardian.Plug.EnsureAuthenticated
  end

  pipeline :ensure_admin do
    plug Guardian.Plug.EnsureAuthenticated
    plug RoboticaHelloWeb.Plug.CheckAdmin
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", RoboticaHelloWeb do
    pipe_through [:browser, :auth]

    get "/", PageController, :index
    get "/login", SessionController, :new
    post "/login", SessionController, :login
    post "/logout", SessionController, :logout
  end

  scope "/", RoboticaHelloWeb do
    pipe_through [:browser, :auth, :ensure_auth]

    get "/instances", InstanceController, :index
  end

  scope "/", RoboticaHelloWeb do
    pipe_through [:browser, :auth, :ensure_admin]

    resources "/users", UserController
    get "/users/:id/password", UserController, :password_edit
    put "/users/:id/password", UserController, :password_update
  end

  # Other scopes may use custom stacks.
  # scope "/api", RoboticaHelloWeb do
  #   pipe_through :api
  # end
end
