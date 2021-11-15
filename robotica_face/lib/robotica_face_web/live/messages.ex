defmodule RoboticaFaceWeb.Live.Messages do
  @moduledoc false
  use Phoenix.LiveView
  use RoboticaCommon.EventBus

  alias RoboticaCommon.Config

  def render(assigns) do
    ~H"""
    <%= if not is_nil(@text) do %>
    <div class="overlay" phx-hook="Message" data-message={@text} id="message">
    <p><%= @text %></p>
    </div>
    <% end %>
    """
  end

  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:text, nil)
      |> assign(:timer, nil)
      |> set_location(Config.ui_default_location())

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

  def handle_cast({:mqtt, _, :action, command}, socket) do
    message = get_in(command, ["message", "text"])

    socket =
      case message do
        nil -> socket
        text -> update_message(socket, text)
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

    RoboticaCommon.EventBus.notify(:unsubscribe_all, %{
      pid: self()
    })

    if location != nil do
      RoboticaCommon.EventBus.notify(:subscribe, %{
        topic: ["action", location, "Robotica"],
        label: :action,
        pid: self(),
        format: :json,
        resend: :no_resend
      })
    end

    socket
    |> assign(:location, location)
  end
end
