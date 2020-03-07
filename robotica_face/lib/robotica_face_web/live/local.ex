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

  def mount(_params, _session, socket) do
    config = RoboticaPlugins.Config.ui_configuration()

    socket =
      socket
      |> assign(:buttons, config.local_buttons)
      |> assign(:location, config.local_location)

    {:ok, socket}
  end

  def handle_event("activate", %{"row" => row_name, "button" => button_name}, socket) do
    buttons = socket.assigns.buttons
    location = socket.assigns.location
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
              nil -> [location]
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
