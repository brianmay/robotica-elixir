defmodule RoboticaUi.Components.Marks do
  @moduledoc false

  use Scenic.Component

  alias Scenic.Graph

  import Scenic.Components
  import Scenic.Primitives

  alias RoboticaPlugins.Mark

  def verify(%RoboticaPlugins.ScheduledStep{} = step), do: {:ok, step}
  def verify(_), do: :invalid_data

  @graph Graph.build(styles: %{}, font_size: 20)
  @timezone Application.compile_env(:robotica_common, :timezone)

  defp date_time_to_local(dt) do
    {:ok, local_dt} = DateTime.shift_zone(dt, @timezone)
    Timex.format!(local_dt, "%F %T", :strftime)
  end

  def init(step, opts) do
    width = opts[:styles][:width]
    height = opts[:styles][:height]

    text = RoboticaPlugins.ScheduledStep.step_to_text(step) |> Enum.join(", ")
    locations = RoboticaPlugins.ScheduledStep.step_to_locations(step)

    graph =
      @graph
      |> rect({width, height}, fill: :black, stroke: {2, :green}, translate: {0, 0})
      |> rect({width - 10, height - 10}, fill: :black, stroke: {1, :green}, translate: {5, 5})
      |> text("Time: #{date_time_to_local(step.required_time)}", translate: {10, 30})
      |> text("Locations: #{Enum.join(locations, ", ")}", translate: {10, 70})
      |> text("Command: #{text}", translate: {10, 110})
      |> text("Mark: #{step.mark || "N/A"}", translate: {10, 150})
      |> button("Done",
        width: width / 2 - 15,
        height: 80,
        translate: {10, height - 180},
        id: :btn_done
      )
      |> button("Cancel",
        width: width / 2 - 15,
        height: 80,
        translate: {width / 2 + 5, height - 180},
        id: :btn_cancel
      )
      |> button("Clear",
        width: width / 2 - 15,
        height: 80,
        translate: {10, height - 90},
        id: :btn_clear
      )
      |> button("Close",
        width: width / 2 - 15,
        height: 80,
        translate: {width / 2 + 5, height - 90},
        id: :btn_close
      )

    {:ok, %{graph: graph, viewport: opts[:viewport], step: step}, push: graph}
  end

  def filter_event({:click, id}, _, state) do
    RoboticaUi.RootManager.reset_screensaver()

    new_mark =
      case id do
        :btn_done -> :done
        :btn_cancel -> :cancelled
        :btn_clear -> :clear
        :btn_close -> nil
      end

    if not is_nil(new_mark) do
      Mark.mark_task(state.step, new_mark)
    end

    send_event({:done, state.step})
    {:halt, state}
  end

  def handle_input(_event, _context, state) do
    RoboticaUi.RootManager.reset_screensaver()
    {:noreply, state}
  end
end
