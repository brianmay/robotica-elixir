defmodule RoboticaFaceWeb.Live.Local do
  use Phoenix.LiveView
  use EventBus.EventSource

  def render(assigns) do
    ~L"""
    <%= for row <- @buttons do %>
    <div>
    <div><%= row.name %></div>
    <%= for button <- row.buttons do %>
    <button class="btn btn-primary btn-robotica" phx-click="activate" phx-value-row="<%= row.name %>" phx-value-button="<%= button.name %>"><%= button.name %></button>
    <% end %>
    </div>
    <% end %>
    """
  end

  def mount(_, socket) do
    config = RoboticaPlugins.Config.ui_configuration()

    socket =
      socket
      |> assign(:buttons, config.local_buttons)
      |> assign(:locations, config.local_locations)

    {:ok, socket}
  end

  def handle_event("activate", %{"row" => row_name, "button" => button_name}, socket) do
    buttons = socket.assigns.buttons
    locations = socket.assigns.locations

    button =
      buttons
      |> Enum.find(%{}, fn row -> row.name == row_name end)
      |> Map.get(:buttons, [])
      |> Enum.find(nil, fn button -> button.name == button_name end)

    case button do
      nil ->
        nil

      button ->
        EventSource.notify %{topic: :local_execute} do
          %RoboticaPlugins.Task{
            locations: locations,
            devices: button.devices,
            action: button.action
          }
        end
    end

    {:noreply, socket}
  end
end
