defmodule RoboticaFaceWeb.Live.Local do
  @moduledoc false
  use RoboticaFaceWeb, :live_view
  use RoboticaCommon.EventBus

  alias RoboticaCommon.Config

  require Logger

  @impl true
  def render(assigns) do
    ~H"""
    <%= live_render(@socket, RoboticaFaceWeb.Live.Messages, id: :messages) %>

    <form phx-change="location">
    <select name="location">
    <option value="">Default (<%= Config.ui_default_location() %>)</option>
    <%= for location <- @locations do %>
    <% selected = if location == @set_location, do: True, else: nil %>
    <option value={location} selected={selected}><%= location %></option>
    <% end %>
    </select>
    </form>
    <%= for row <- @buttons do %>
    <div>
    <div><%= row.name %></div>
    <%= for button <- row.buttons do %>
    <% class = get_button_state(@button_states, button.id) |> button_state_to_class(button) %>
    <button class={"btn #{class} btn-robotica"} phx-click="activate" phx-value-button={button.id}><%= button.name %></button>
    <% end %>
    </div>
    <% end %>
    """
  end

  @impl true
  @spec mount(any, nil | maybe_improper_list | map, Phoenix.LiveView.Socket.t()) ::
          {:ok, Phoenix.LiveView.Socket.t()}
  def mount(_params, _session, socket) do
    locations = Config.ui_locations()

    socket =
      socket
      |> assign(:active, "local")
      |> assign(:locations, locations)

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    set_location = params["location"]

    location =
      case set_location do
        nil -> Config.ui_default_location()
        location -> location
      end

    socket =
      socket
      |> assign(:set_location, set_location)
      |> set_location(location)

    {:noreply, socket}
  end

  @impl true
  def handle_cast({:mqtt, _, {button_id, label}, data}, socket) do
    socket =
      case get_button(socket, button_id) do
        nil ->
          Logger.error("Unknown button #{button_id}")
          socket

        button ->
          button_state = get_button_state(socket.assigns.button_states, button_id)

          button_state = RoboticaCommon.Buttons.process_message(button, label, data, button_state)

          button_states = Map.put(socket.assigns.button_states, button_id, button_state)
          assign(socket, :button_states, button_states)
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event("location", param, socket) do
    url = Routes.local_path(socket, :local, param["location"])
    socket = push_patch(socket, to: url)
    {:noreply, socket}
  end

  @impl true
  def handle_event("activate", %{"button" => button_id}, socket) do
    button = get_button(socket, button_id)
    Logger.info("robotica_face: Got button press #{button.name}")

    case button do
      nil ->
        Logger.error("Unknown button #{button_id}")

      button ->
        button_state = get_button_state(socket.assigns.button_states, button_id)
        RoboticaCommon.Buttons.execute_press_commands(button, button_state)
    end

    {:noreply, socket}
  end

  defp search_row(row, button_id) do
    Enum.find(row, nil, fn button -> button.id == button_id end)
  end

  defp search_button([], _), do: nil

  defp search_button([head | tail], button_id) do
    case search_row(head.buttons, button_id) do
      nil -> search_button(tail, button_id)
      button -> button
    end
  end

  defp get_button(socket, button_id) do
    search_button(socket.assigns.buttons, button_id)
  end

  defp get_button_state(button_states, id) do
    Map.get(button_states, id)
  end

  @spec display_state_to_class(RoboticaCommon.Buttons.display_state()) :: String.t()
  defp display_state_to_class(:state_on), do: "btn-success"
  defp display_state_to_class(:state_off), do: "btn-primary"
  defp display_state_to_class(:state_hard_off), do: "btn-light"
  defp display_state_to_class(:state_error), do: "btn-danger"
  defp display_state_to_class(nil), do: "btn-secondary"

  defp button_state_to_class(button_state, button) do
    RoboticaCommon.Buttons.get_display_state(button, button_state) |> display_state_to_class()
  end

  defp set_location(socket, location) do
    locations = Config.ui_locations()

    buttons =
      case Enum.member?(locations, location) do
        true -> Config.ui_local_buttons(location)
        false -> []
      end

    RoboticaCommon.Buttons.unsubscribe_all()

    button_states =
      Enum.reduce(buttons, %{}, fn row, button_states ->
        Enum.reduce(row.buttons, button_states, fn button, button_states ->
          RoboticaCommon.Buttons.subscribe_topics(button)
          Map.put(button_states, button.id, RoboticaCommon.Buttons.get_initial_state(button))
        end)
      end)

    socket
    |> assign(:buttons, buttons)
    |> assign(:button_states, button_states)
    |> assign(:location, location)
  end
end
