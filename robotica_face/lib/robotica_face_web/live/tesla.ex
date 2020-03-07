defmodule RoboticaFaceWeb.Live.Tesla do
  use Phoenix.LiveView

  def render(assigns) do
    RoboticaFaceWeb.LiveView.render("tesla.html", assigns)
  end

  def mount(_params, _session, socket) do
    RoboticaFace.Tesla.register(self())
    tesla_state = RoboticaFace.Tesla.get_tesla_state()
    {:ok, assign(socket, :tesla_state, tesla_state)}
  end

  def handle_cast({:update_tesla_state, tesla_state}, socket) do
    {:noreply, assign(socket, :tesla_state, tesla_state)}
  end

  def handle_cast(:clear, socket) do
    {:noreply, assign(socket, :text, nil)}
  end
end
