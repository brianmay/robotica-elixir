defmodule RoboticaFaceWeb.Live.Remote do
  use Phoenix.LiveView
  use EventBus.EventSource

  def render(assigns) do
    ~L"""
    <table>
    <body>
    <tr>
    <td>Locations</td>
    <%= for location <- @all_locations do %>
    <%= if MapSet.member?(@locations, location) do %>
    <td><button phx-click="location" phx-value-location="<%= location %>" phx-value-set="off"><%= location %></button></td>
    <% else %>
    <td><button class="button-outline" phx-click="location" phx-value-location="<%= location %>" phx-value-set="on"><%= location %></button></td>
    <% end %>
    <% end %>
    </tr>
    <%= for row <- @buttons do %>
    <tr>
    <td><%= row.name %></td>
    <%= for button <- row.buttons do %>
    <td><button phx-click="activate" phx-value-row="<%= row.name %>" phx-value-button="<%= button.name %>"><%= button.name %></button></td>
    <% end %>
    </tr>
    <% end %>
    </body>
    </table>
    """
  end

  def mount(_, socket) do
    config = RoboticaPlugins.Config.ui_configuration()

    socket =
      socket
      |> assign(:buttons, config.remote_buttons)
      |> assign(:all_locations, config.remote_locations)
      |> assign(:locations, MapSet.new())

    {:ok, socket}
  end

  def handle_event("location", %{"location" => location, "set" => value}, socket) do
    locations = socket.assigns.locations

    locations =
      case value do
        "off" -> MapSet.delete(locations, location)
        "on" -> MapSet.put(locations, location)
      end

    socket =
      socket
      |> assign(:locations, locations)

    {:noreply, socket}
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
        EventSource.notify %{topic: :remote_execute} do
          %RoboticaPlugins.Task{
            locations: MapSet.to_list(locations),
            action: button.action
          }
        end
    end

    {:noreply, socket}
  end
end
