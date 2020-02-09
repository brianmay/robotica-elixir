defmodule RoboticaFaceWeb.Live.Schedule do
  use Phoenix.LiveView

  def render(assigns) do
    ~L"""
    <div class="table-responsive">
    <table class="table schedule">
      <thead>
        <tr>
          <th scope="col">Time</th>
          <th scope="col">Location</th>
          <th scope="col">Message</th>
          <th scope="col">Marks</th>
          <th scope="col">Actions</th>
        </th>
      </thead>
      <tbody>
        <%= for step <- @schedule do %>
          <% iso_time = Calendar.DateTime.Format.iso8601(step.required_time) %>
            <tr class="<%= step.mark %>">
              <td><%= date_time_to_local(step.required_time) %></td>
              <td><%= get_step_locations(step) %></td>
              <td><%= get_step_message(step) %></td>
              <td><%= step.mark %></td>
              <td>
                <button class="btn btn-warning" phx-click="mark" phx-value-mark="done" phx-value-step_time="<%= iso_time %>" phx-value-step_id="<%= step.id %>">Done</button>
                <button class="btn btn-warning" phx-click="mark" phx-value-mark="cancel" phx-value-step_time="<%= iso_time %>" phx-value-step_id="<%= step.id %>">Cancel</button>
                <button class="btn btn-warning" phx-click="mark" phx-value-mark="clear" phx-value-step_time="<%= iso_time %>" phx-value-step_id="<%= step.id %>">Clear</button>
              </td>
            </tr>
        <% end %>
       </tbody>
    </table>
    </div>
    """
  end

  def mount(_, socket) do
    RoboticaFace.Schedule.register(self())
    schedule = get_schedule()
    {:ok, assign(socket, :schedule, schedule)}
  end

  def handle_cast({:schedule, schedule}, socket) do
    {:noreply, assign(socket, :schedule, schedule)}
  end

  defp date_time_to_local(dt) do
    dt
    |> Calendar.DateTime.shift_zone!("Australia/Melbourne")
    |> Timex.format!("%F %T", :strftime)
  end

  defp get_schedule() do
    case RoboticaFace.Schedule.get_schedule() do
      {:ok, schedule} -> schedule
      :error -> []
    end
  end

  defp get_step_message(step) do
    RoboticaPlugins.ScheduledStep.step_to_text(step)
  end

  defp get_step_locations(step) do
    RoboticaPlugins.ScheduledStep.step_to_locations(step)
    |> Enum.join(", ")
  end

  defp head_or_nil([]), do: nil
  defp head_or_nil([head | _]), do: head

  defp get_step(schedule, step_time, step_id) do
    schedule
    |> Enum.filter(fn step -> DateTime.compare(step.required_time, step_time) == :eq end)
    |> Enum.filter(fn step -> step.id == step_id end)
    |> head_or_nil
  end

  defp do_mark(task, status) do
    RoboticaPlugins.Mark.mark_task(task, status)
  end

  def handle_event("mark", %{"mark" => status, "step_time" => step_time, "step_id" => id}, socket) do
    step_time = Timex.parse!(step_time, "{ISO:Extended}")

    status =
      case status do
        "done" -> :done
        "cancel" -> :cancelled
        "clear" -> :clear
      end

    case get_step(socket.assigns.schedule, step_time, id) do
      nil -> nil
      step -> do_mark(step, status)
    end

    {:noreply, socket}
  end
end
