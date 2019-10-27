defmodule RoboticaFaceWeb.Live.Tesla do
  use Phoenix.LiveView

  def render(assigns) do
    ~L"""
    <%= if @tesla_state != %{} do %>
    <table>
    <tbody>

    <tr>
    <th>
    <td>Battery Charge</td>
    <td><%= @tesla_state["state"]["battery_level"] %></td>
    </th>
    </tr>

    <tr>
    <th>
    <td>Charger Plugged In</td>
    <td><%= @tesla_state["state"]["charger_plugged_in"] %></td>
    </th>
    </tr>

    <tr>
    <th>
    <td>Is Home</td>
    <td><%= @tesla_state["state"]["is_home"] %></td>
    </th>
    </tr>

    <tr>
    <th>
    <td>Unlocked time</td>
    <td><%= @tesla_state["state"]["unlocked_time"] %></td>
    </th>
    </tr>

    <tr>
    <th>
    <td>Unlocked Delta</td>
    <td><%= @tesla_state["state"]["unlocked_delta"] %></td>
    </th>
    </tr>

    <tr>
    <th>
    <td>Battery Charge Time</td>
    <td><%= @tesla_state["history"]["battery_charge_time"] * 60 %></td>
    </th>
    </tr>

    <tr>
    <th>
    <td>Outside Temperature</td>
    <td><%= @tesla_state["history"]["outside_temp"] %></td>
    </th>
    </tr>

    <tr>
    <th>
    <td>Inside Temperature</td>
    <td><%= @tesla_state["history"]["inside_temp"] %></td>
    </th>
    </tr>

    </tbody>
    </table>
    <% else %>
    No state date found.
    <% end %>
    """
  end

  def mount(_, socket) do
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
