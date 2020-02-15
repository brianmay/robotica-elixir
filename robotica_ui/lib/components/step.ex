defmodule RoboticaUi.Components.Step do
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

  def draw(step, width, background_color \\ :black) do
    foreground_color =
      case step.mark do
        :done -> :green
        :cancelled -> :red
        _ -> :white
      end

    text = RoboticaPlugins.ScheduledStep.step_to_text(step)

    @graph
    |> rect({width, 40}, fill: background_color, translate: {0, 0})
    |> text(date_time_to_local(step.required_time), translate: {10, 30}, fill: foreground_color)
    |> text(text || "N/A", translate: {110, 30}, fill: foreground_color)
  end

  def init(step, opts) do
    width = opts[:styles][:width]
    graph = draw(step, width)

    {:ok, %{step: step, width: width}, push: graph}
  end

  def handle_input({:cursor_button, {:left, :press, 0, _click_pos}}, _context, state) do
    graph = draw(state.step, state.width, :blue)
    RoboticaUi.RootManager.reset_screensaver()
    {:noreply, state, push: graph}
  end

  def handle_input({:cursor_button, {:left, :release, 0, _click_pos}}, _context, state) do
    send_event({:click, state.step})
    RoboticaUi.RootManager.reset_screensaver()
    {:noreply, state}
  end

  def handle_input(_event, _context, state) do
    RoboticaUi.RootManager.reset_screensaver()
    {:noreply, state}
  end
end
