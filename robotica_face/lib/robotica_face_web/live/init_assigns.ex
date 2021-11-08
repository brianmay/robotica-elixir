defmodule RoboticaFaceWeb.InitAssigns do
  import Phoenix.LiveView

  alias RoboticaFaceWeb.Router.Helpers, as: Routes

  def mount(_params, session, socket) do
    user = session["claims"]

    if user == nil do
      socket = put_flash(socket, :danger, "Your session has expired.")
      socket = redirect(socket, to: Routes.page_path(socket, :index))
      {:halt, socket}
    else
      socket = assign(socket, :user, user)
      {:cont, socket}
    end
  end
end
