defmodule RoboticaUi.Components.Nav do
  @moduledoc false

  use Scenic.Component

  alias Scenic.Graph

  import Scenic.Primitives
  import Scenic.Clock.Components

  def validate(tab) when is_atom(tab), do: {:ok, tab}
  def validate(_), do: :invalid_data

  # build the path to the static asset file (compile time)
  @timezone Application.compile_env(:robotica_common, :timezone)

  @scenes [
    {:clock, {0, 0}},
    {:schedule, {0, 100}},
    {:local, {0, 200}}
  ]

  defp in_bounding_box({click_x, click_y}, {x, y}) do
    x2 = x + 100
    y2 = y + 100
    click_x >= x and click_x < x2 and click_y >= y and click_y < y2
  end

  @graph Graph.build(styles: %{}, font_size: 20)
         |> rect({100, 400}, fill: :green)
         |> line({{0, 100}, {100, 100}}, stroke: {1, :red})
         |> line({{0, 200}, {100, 200}}, stroke: {1, :red})
         |> line({{0, 300}, {100, 300}}, stroke: {1, :red})

  def init(scene, tab, _opts) do
    scenes = Enum.filter(@scenes, fn {scene_tab, _} -> scene_tab == tab end)

    icon_position =
      case scenes do
        [{_, icon_position} | _] -> icon_position
        _ -> {0, 0}
      end

    graph =
      @graph
      |> rect({100, 100}, fill: :red, translate: icon_position)
      |> analog_clock(radius: 40, translate: {50, 50}, timezone: @timezone)
      |> rect({80, 80}, fill: {:black, 0}, translate: {10, 10})
      |> rect({80, 80}, fill: {:image, :schedule}, translate: {10, 110})
      |> rect({80, 80}, fill: {:image, :local}, translate: {10, 210})

    scene = push_graph(scene, graph)

    :ok = request_input(scene, :cursor_button)
    {:ok, scene}
  end

  def handle_input({:cursor_button, {:btn_left, 0, _, click_pos}}, _, scene) do
    scenes = Enum.filter(@scenes, fn {_, icon_pos} -> in_bounding_box(click_pos, icon_pos) end)

    case scenes do
      [{tab, _} | _] -> RoboticaUi.RootManager.set_tab(tab)
      _ -> nil
    end

    RoboticaUi.RootManager.reset_screensaver()
    {:noreply, scene}
  end

  def handle_input(_event, _, scene) do
    RoboticaUi.RootManager.reset_screensaver()
    {:noreply, scene}
  end
end
