defmodule RoboticaFaceWeb.Live.Local do
  use Phoenix.LiveView
  use EventBus.EventSource

  def render(assigns) do
    ~L"""
    <table>
    <body>
    <%= for row <- @buttons do %>
    <tr>
    <td><%= row.name %></td>
    <%= for button <- row.buttons do %>
    <td><button phx-click="<%= button.name %>"><%= button.name %></button></td>
    <% end %>
    </tr>
    <% end %>
    </body>
    </table>
    """
  end

  def mount(_, socket) do
    config = RoboticaFace.Config.configuration()

    socket =
      socket
      |> assign(:buttons, config.local_buttons)
      |> assign(:locations, config.local_locations)

    {:ok, socket}
  end

  def handle_event(button_name, _value, socket) do
    buttons = socket.assigns.buttons
    locations = socket.assigns.locations

    button =
      buttons
      |> Enum.map(fn row ->
        Enum.find(row.buttons, nil, fn button -> button.name == button_name end)
      end)
      |> Enum.find(fn button -> not is_nil(button) end)

    case button do
      nil ->
        nil

      button ->
        EventSource.notify %{topic: :local_execute} do
          %RoboticaPlugins.Task{
            locations: locations,
            action: button.action
          }
        end
    end

    {:noreply, socket}
  end
end
