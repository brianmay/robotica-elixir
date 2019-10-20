defmodule RoboticaUi.Components.Marks do
  @moduledoc false

  use Scenic.Component

  alias Scenic.Graph

  import Scenic.Components
  import Scenic.Primitives

  alias RoboticaUi.Mark

  def verify(step), do: {:ok, step}

  @graph Graph.build(styles: %{}, font_size: 20)
  @timezone Application.get_env(:robotica_ui, :timezone)

  defp date_time_to_local(dt) do
    dt
    |> Calendar.DateTime.shift_zone!(@timezone)
    |> Timex.format!("%F %T", :strftime)
  end

  def init(step, opts) do
    width = opts[:styles][:width]
    height = opts[:styles][:height]

    task = step.task

    text =
      case task.action.message do
        nil -> nil
        msg -> msg.text
      end

    graph =
      @graph
      |> rect({width, height}, fill: :black, stroke: {2, :green}, translate: {0, 0})
      |> rect({width - 10, height - 10}, fill: :black, stroke: {1, :green}, translate: {5, 5})
      |> text("Time: #{date_time_to_local(step.required_time)}", translate: {10, 30})
      |> text("Locations: #{Enum.join(task.locations, ", ")}", translate: {10, 70})
      |> text("Message: #{text || "N/A"}", translate: {10, 110})
      |> text("Mark: #{task.mark || "N/A"}", translate: {10, 150})
      |> button("Done",
        width: width / 2 - 15,
        height: 80,
        translate: {10, height - 180},
        id: :btn_done
      )
      |> button("Postpone",
        width: width / 2 - 15,
        height: 80,
        translate: {width / 2 + 5, height - 180},
        id: :btn_postpone
      )
      |> button("Clear",
        width: width / 2 - 15,
        height: 80,
        translate: {10, height - 90},
        id: :btn_clear
      )
      |> button("Cancel",
        width: width / 2 - 15,
        height: 80,
        translate: {width / 2 + 5, height - 90},
        id: :btn_cancel
      )

    {:ok, %{graph: graph, viewport: opts[:viewport], step: step}, push: graph}
  end

  def filter_event({:click, id}, _, state) do
    RoboticaUi.RootManager.reset_screensaver()

    case id do
      :btn_done -> Mark.mark_task(state.step, :done)
      :btn_postpone -> Mark.mark_task(state.step, :postponed)
      :btn_clear -> Mark.mark_task(state.step, :clear)
      :btn_cancel -> nil
    end

    send_event({:done, state.step})
    {:halt, state}
  end

  def handle_input(_event, _context, state) do
    RoboticaUi.RootManager.reset_screensaver()
    {:noreply, state}
  end
end
