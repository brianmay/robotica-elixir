defmodule RoboticaFaceWeb.Live.Messages do
  use Phoenix.LiveView

  alias RoboticaPlugins.Config

  def render(assigns) do
    ~L"""
    <%= if not is_nil(@text) do %>
    <div class="overlay" phx-hook="Message" data-message="<%= @text %>">
    <p><%= @text %></p>
    </div>
    <% end %>
    """
  end

  def mount(_params, session, socket) do
    RoboticaFace.Execute.register(self())

    socket =
      socket
      |> assign(:text, nil)
      |> assign(:timer, nil)
      |> set_location(session["user"]["location"])

    {:ok, socket}
  end

  def update_message(socket, text) do
    case socket.assigns.timer do
      nil -> nil
      timer -> Process.cancel_timer(timer)
    end

    timer =
      case text do
        nil -> nil
        _ -> Process.send_after(self(), :timer, 10_000)
      end

    socket
    |> assign(:text, text)
    |> assign(:timer, timer)
  end

  def handle_cast({:execute, task}, socket) do
    location = socket.assigns.location

    good_location = Enum.any?(task.locations, fn l -> l == location end)
    message = RoboticaPlugins.Action.action_to_message(task.action)

    socket =
      case {good_location, message} do
        {false, _} -> socket
        {_, nil} -> socket
        {_, text} -> update_message(socket, text)
      end

    {:noreply, socket}
  end

  def handle_info(:timer, socket) do
    socket =
      socket
      |> assign(:text, nil)
      |> assign(:timer, nil)

    {:noreply, socket}
  end

  defp set_location(socket, location) do
    locations = Config.ui_locations()

    location =
      case Enum.member?(locations, location) do
        true -> location
        false -> nil
      end

    socket
    |> assign(:location, location)
  end
end
