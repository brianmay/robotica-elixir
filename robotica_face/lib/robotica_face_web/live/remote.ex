defmodule RoboticaFaceWeb.Live.Remote do
  use Phoenix.LiveView
  use EventBus.EventSource

  alias RoboticaPlugins.Config

  def render(assigns) do
    ~L"""
    <div>
    <div>Locations</div>
    <%= for location <- @all_locations do %>
    <%= if MapSet.member?(@locations, location) do %>
    <button class="btn btn-primary btn-robotica" phx-click="location" phx-value-location="<%= location %>" phx-value-set="off"><%= location %></button>
    <% else %>
    <button class="btn btn-secondary btn-robotica" phx-click="location" phx-value-location="<%= location %>" phx-value-set="on"><%= location %></button>
    <% end %>
    <% end %>
    </div>

    <%= for row <- @buttons do %>
    <div>
    <div><%= row.name %></div>
    <%= for button <- row.buttons do %>
    <button class="btn-primary btn-robotica" phx-click="activate" phx-value-row="<%= row.name %>" phx-value-button="<%= button.name %>"><%= button.name %></button>
    <% end %>
    </div>
    <% end %>
    """
  end

  def mount(_params, _session, socket) do
    config = Config.ui_configuration()

    socket =
      socket
      |> assign(:buttons, config.remote_buttons)
      |> assign(:all_locations, MapSet.new(Config.ui_locations()))
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
    event_params = %{topic: :remote_execute}

    button =
      buttons
      |> Enum.find(%{}, fn row -> row.name == row_name end)
      |> Map.get(:buttons, [])
      |> Enum.find(nil, fn button -> button.name == button_name end)

    case button do
      nil ->
        nil

      button ->
        Enum.each(button.tasks, fn task ->
          locations =
            case task.locations do
              nil -> MapSet.to_list(locations)
              locations -> locations
            end

          EventSource.notify event_params do
            %RoboticaPlugins.Task{
              locations: locations,
              devices: task.devices,
              action: task.action
            }
          end
        end)
    end

    {:noreply, socket}
  end
end
