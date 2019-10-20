defmodule RoboticaFaceWeb.Live.Schedule do
  use Phoenix.LiveView

  def render(assigns) do
    ~L"""
    <table>
      <thead>
        <tr>
          <th>Time</th>
          <th>Locations</th>
          <th>Message</th>
          <th>Marks</th>
          <th>Actions</th>
        </th>
      </thead>
      <tbody>
        <%= for step <- @schedule do %>
          <% iso_time = Calendar.DateTime.Format.iso8601(step.required_time) %>
          <%= for task <- step.tasks do %>
            <tr>
              <td><%= date_time_to_local(step.required_time) %></td>
              <td><%= Enum.join(task.locations, ", ") %></td>
              <td><%= get_task_message(task) %></td>
              <td><%= task.mark %></td>
              <td>
                <button phx-click="mark" phx-value-mark="done" phx-value-step_time="<%= iso_time %>" phx-value-task_id="<%= task.id %>">Done</button>
                <button phx-click="mark" phx-value-mark="postponed" phx-value-step_time="<%= iso_time %>" phx-value-task_id="<%= task.id %>">Postpone</button>
                <button phx-click="mark" phx-value-mark="clear" phx-value-step_time="<%= iso_time %>" phx-value-task_id="<%= task.id %>">Clear</button>
              </td>
            </tr>
          <% end %>
        <% end %>
       </tbody>
    </table>
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

  defp get_task_message(task) do
    RoboticaPlugins.ScheduledTask.task_to_msg(task)
  end

  defp head_or_nil([]), do: nil
  defp head_or_nil([head | _]), do: head

  defp get_step(schedule, step_time, task_id) do
    step =
      schedule
      |> Enum.filter(fn step -> DateTime.compare(step.required_time, step_time) == :eq end)
      |> head_or_nil

    task =
      case step do
        nil ->
          nil

        _ ->
          step.tasks
          |> Enum.filter(fn task -> task.id == task_id end)
          |> head_or_nil
      end

    case task do
      nil ->
        nil

      _ ->
        %RoboticaPlugins.SingleStep{
          required_time: step.required_time,
          latest_time: step.latest_time,
          task: task
        }
    end
  end

  defp do_mark(task, status) do
    RoboticaFace.Mark.mark_task(task, status)
  end

  def handle_event("mark", %{"mark" => status, "step_time" => step_time, "task_id" => id}, socket) do
    step_time = Timex.parse!(step_time, "{ISO:Extended}")

    status =
      case status do
        "done" -> :done
        "postpone" -> :cancelled
        "clear" -> :clear
      end

    case get_step(socket.assigns.schedule, step_time, id) do
      nil -> nil
      step -> do_mark(step, status)
    end

    {:noreply, socket}
  end
end
