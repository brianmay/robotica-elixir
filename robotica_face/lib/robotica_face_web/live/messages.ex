defmodule RoboticaFaceWeb.Live.Messages do
  use Phoenix.LiveView

  def render(assigns) do
    ~L"""
    <%= if not is_nil(@action) do %>
    <div class="overlay">
    <p>Last message: <%= inspect @action %></p>
    </div>
    <% end %>
    """
  end

  def mount(_, socket) do
    RoboticaFace.Execute.register(self())
    {:ok, assign(socket, :action, nil)}
  end

  def handle_cast({:execute, action}, socket) do
    {:noreply, assign(socket, :action, action)}
  end

  def handle_cast(:clear, socket) do
    {:noreply, assign(socket, :action, nil)}
  end
end
