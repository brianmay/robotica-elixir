defmodule RoboticaFaceWeb.Live.Messages do
  use Phoenix.LiveView

  def render(assigns) do
    ~L"""
    <%= if not is_nil(@text) do %>
    <div class="overlay">
    <p><%= inspect @text %></p>
    </div>
    <% end %>
    """
  end

  def mount(_, socket) do
    RoboticaFace.Execute.register(self())
    {:ok, assign(socket, :text, nil)}
  end

  def handle_cast({:execute, action}, socket) do
    text =
      case action.message do
        nil -> nil
        message -> Map.get(message, :text)
      end

    {:noreply, assign(socket, :text, text)}
  end

  def handle_cast(:clear, socket) do
    {:noreply, assign(socket, :text, nil)}
  end
end
