defmodule RoboticaFaceWeb.Live.Messages do
  use Phoenix.LiveView

  def render(assigns) do
    ~L"""
    <%= if not is_nil(@text) do %>
    <div class="overlay">
    <p><%= @text %></p>
    </div>
    <% end %>
    """
  end

  def mount(_, socket) do
    RoboticaFace.Execute.register(self())

    socket =
      socket
      |> assign(:text, nil)
      |> assign(:timer, nil)

    {:ok, socket}
  end

  def handle_cast({:execute, action}, socket) do
    text = RoboticaPlugins.Action.action_to_message(action)

    case socket.assigns.timer do
      nil -> nil
      timer -> Process.cancel_timer(timer)
    end

    timer =
      case text do
        nil -> nil
        _ -> Process.send_after(self(), :timer, 10_000)
      end

    socket =
      socket
      |> assign(:text, text)
      |> assign(:timer, timer)

    {:noreply, socket}
  end

  def handle_info(:timer, socket) do
    socket =
      socket
      |> assign(:text, nil)
      |> assign(:timer, nil)

    {:noreply, socket}
  end
end
