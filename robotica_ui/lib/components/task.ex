defmodule RoboticaUi.Components.Task do
  @moduledoc false

  use Scenic.Component

  alias Scenic.Graph
  import Scenic.Primitives

  def verify(step), do: {:ok, step}

  @timezone Application.get_env(:robotica_plugins, :timezone)
  @graph Graph.build(styles: %{}, font_size: 20)

  defp date_time_to_local(dt) do
    {:ok, local_dt} = DateTime.shift_zone(dt, @timezone)
    {:ok, local_now} = DateTime.shift_zone(DateTime.utc_now(), @timezone)

    date_offset =
      case Date.diff(local_dt, local_now) do
        0 -> ""
        x when x > 0 -> "+#{x}"
      end

    Timex.format!(local_dt, "%T#{date_offset}", :strftime)
  end

  def init(step, opts) do
    width = opts[:styles][:width]
    task = step.task

    text = RoboticaPlugins.ScheduledTask.task_to_text(task)

    color =
      case task.mark do
        :done -> :green
        :cancelled -> :red
        _ -> :white
      end

    graph =
      @graph
      |> rect({width, 40}, fill: {:green, 0}, translate: {0, 0})
      |> text(date_time_to_local(step.required_time), translate: {10, 30}, fill: color)
      |> text(Enum.join(task.locations, ", "), translate: {110, 30}, fill: color)
      |> text(text || "N/A", translate: {310, 30}, fill: color)

    {:ok, %{step: step}, push: graph}
  end

  def handle_input({:cursor_button, {:left, :press, 0, _click_pos}}, _context, state) do
    send_event({:click, state.step})

    RoboticaUi.RootManager.reset_screensaver()
    {:noreply, state}
  end

  def handle_input(_event, _context, state) do
    RoboticaUi.RootManager.reset_screensaver()
    {:noreply, state}
  end
end
