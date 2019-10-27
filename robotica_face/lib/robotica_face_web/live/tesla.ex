defmodule RoboticaFaceWeb.Live.Tesla do
  use Phoenix.LiveView

  @timezone Application.get_env(:robotica_plugins, :timezone)

  def render(assigns) do
    ~L"""
    <%= if @tesla_state != %{} do %>
    <table>
    <tbody>

    <tr>
    <th>Last Update time</th>
    <td><%= @tesla_state["history"]["date_time"] |> date_time_to_local %></td>
    </tr>

    <tr>
    <th>Battery Charge</th>
    <td><%= @tesla_state["state"]["battery_level"] %></td>
    </tr>

    <tr>
    <th>Charger Plugged In</th>
    <td><%= @tesla_state["state"]["charger_plugged_in"] %></td>
    </th>
    </tr>

    <tr>
    <th>Is Home</th>
    <td><%= @tesla_state["state"]["is_home"] %></td>
    </tr>

    <tr>
    <th>Unlocked time</th>
    <td><%= @tesla_state["state"]["unlocked_time"] |> date_time_to_local %></td>
    </tr>

    <tr>
    <th>Unlocked Delta</th>
    <td><%= @tesla_state["state"]["unlocked_delta"] %></td>
    </tr>

    <tr>
    <th>Battery Charge Time</th>
    <td><%= @tesla_state["history"]["battery_charge_time"] * 60 %></td>
    </tr>

    <tr>
    <th>Outside Temperature</th>
    <td><%= @tesla_state["history"]["outside_temp"] %></td>
    </tr>

    <tr>
    <th>Inside Temperature</th>
    <td><%= @tesla_state["history"]["inside_temp"] %></td>
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

  defp date_time_to_local(nil), do: nil

  defp date_time_to_local(dt) do
    dt
    |> Timex.parse!("{ISO:Extended}")
    |> Timex.Timezone.convert(@timezone)
    |> Timex.format!("%F %T", :strftime)
  end

end
