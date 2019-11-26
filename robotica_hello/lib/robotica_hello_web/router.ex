defmodule RoboticaHelloWeb.Router do
  use RoboticaHelloWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", RoboticaHelloWeb do
    pipe_through :browser

    get "/", PageController, :index
    resources "/users", UserController
    get "/users/:id/password", UserController, :password_edit
    put "/users/:id/password", UserController, :password_update
  end

  # Other scopes may use custom stacks.
  # scope "/api", RoboticaHelloWeb do
  #   pipe_through :api
  # end
end
