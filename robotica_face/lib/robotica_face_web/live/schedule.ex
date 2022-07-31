defmodule RoboticaFaceWeb.Live.Schedule do
  @moduledoc false
  use RoboticaFaceWeb, :live_view
  use RoboticaCommon.EventBus

  require Logger

  alias Robotica.CommonConfig
  alias Robotica.Schema
  alias Robotica.Types.ScheduledStep

  def render(assigns) do
    ~H"""
    <%= live_render(@socket, RoboticaFaceWeb.Live.Messages, id: :messages) %>

    <div class="table-responsive">
    <table class="table schedule">
      <thead>
        <tr>
          <th scope="col">Time</th>
          <th scope="col">Step</th>
          <th scope="col">Marks</th>
          <th scope="col">Actions</th>
        </tr>
      </thead>
      <tbody>
        <%= for step <- @schedule do %>
          <% iso_time = DateTime.to_iso8601(step.required_time) %>
            <tr class={step.mark}>
              <td><%= date_time_to_local(step.required_time) %></td>
              <td>
                <%= for line <- get_step_message(step) do %>
                  <p><%= line %></p>
                <% end %>
              </td>
              <td><%= step.mark %></td>
              <td>
                <button class="btn btn-warning" phx-click="mark" phx-value-mark="done" phx-value-step_time={iso_time} phx-value-step_id={step.id}>Done</button>
                <button class="btn btn-warning" phx-click="mark" phx-value-mark="cancel" phx-value-step_time={iso_time} phx-value-step_id={step.id}>Cancel</button>
                <button class="btn btn-warning" phx-click="mark" phx-value-mark="clear" phx-value-step_time={iso_time} phx-value-step_id={step.id}>Clear</button>
              </td>
            </tr>
        <% end %>
       </tbody>
    </table>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    schedule_host = CommonConfig.ui_schedule_hostname()

    RoboticaCommon.EventBus.notify(:subscribe, %{
      topic: "schedule/#{schedule_host}",
      label: :schedule,
      pid: self(),
      format: :json,
      resend: :resend
    })

    schedule = []

    socket =
      socket
      |> assign(:active, "schedule")
      |> assign(:schedule, schedule)

    {:ok, socket}
  end

  def handle_cast({:mqtt, _, :schedule, schedule}, socket) do
    case Schema.validate_scheduled_steps(schedule) do
      {:ok, steps} ->
        {:noreply, assign(socket, :schedule, steps)}

      {:error, reason} ->
        Logger.error("Invalid schedule message received: #{inspect(reason)}.")
        {:noreply, socket}
    end
  end

  defp date_time_to_local(dt) do
    dt
    |> DateTime.shift_zone!("Australia/Melbourne")
    |> Timex.format!("%F %T", :strftime)
  end

  defp get_step_message(step) do
    ScheduledStep.step_to_text(step, include_locations: true)
  end

  defp head_or_nil([]), do: nil
  defp head_or_nil([head | _]), do: head

  defp get_step(schedule, step_time, step_id) do
    schedule
    |> Enum.filter(fn step ->
      DateTime.compare(step.required_time, step_time) == :eq and step.id == step_id
    end)
    |> head_or_nil
  end

  defp do_mark(task, status) do
    Robotica.Mark.mark_task(task, status)
  end

  def handle_event("mark", %{"mark" => status, "step_time" => step_time, "step_id" => id}, socket) do
    {:ok, step_time, 0} = DateTime.from_iso8601(step_time)

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
