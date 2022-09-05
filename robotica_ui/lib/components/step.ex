defmodule RoboticaUi.Components.Step do
  @moduledoc false
  @font :roboto
  @font_size 16

  use Scenic.Component

  # alias Scenic.Assets.Static
  alias Scenic.Graph
  import Scenic.Primitives

  alias Robotica.Types.ScheduledStep

  def validate(%ScheduledStep{} = step), do: {:ok, step}
  def validate(_), do: :invalid_data

  @timezone Application.compile_env(:robotica_common, :timezone)
  @graph Graph.build(styles: %{}, font: @font, font_size: @font_size)

  def date_time_to_local(dt) do
    {:ok, local_dt} = DateTime.shift_zone(dt, @timezone)
    {:ok, local_now} = DateTime.shift_zone(DateTime.utc_now(), @timezone)

    date_offset =
      case Date.diff(local_dt, local_now) do
        0 -> ""
        x when x > 0 -> "+#{x}"
        x when x < 0 -> "#{x}"
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

    text =
      ScheduledStep.step_to_text(step)
      |> Enum.join(", ")

    @graph
    |> rect({width, 40},
      fill: background_color,
      translate: {0, 0},
      id: :btn,
      input: :cursor_button
    )
    |> text(date_time_to_local(step.required_time), translate: {10, 30}, fill: foreground_color)
    |> text(text, translate: {110, 30}, fill: foreground_color)
  end

  def init(scene, step, opts) do
    width = opts[:width]
    graph = draw(step, width)

    scene =
      scene
      |> assign(step: step, width: width)
      |> push_graph(graph)

    {:ok, scene}
  end

  def handle_input({:cursor_button, {:btn_left, 1, _, _click_pos}}, _id, scene) do
    {:ok, scene}
    graph = draw(scene.assigns.step, scene.assigns.width, :blue)
    scene = push_graph(scene, graph)

    {:ok, scene}
    RoboticaUi.RootManager.reset_screensaver()
    {:noreply, scene}
  end

  def handle_input({:cursor_button, {:btn_left, 0, _, _click_pos}}, _id, scene) do
    :ok = send_parent_event(scene, {:click, scene.assigns.step})
    RoboticaUi.RootManager.reset_screensaver()
    {:noreply, scene}
  end

  def handle_input(_event, _, scene) do
    RoboticaUi.RootManager.reset_screensaver()
    {:noreply, scene}
  end
end
