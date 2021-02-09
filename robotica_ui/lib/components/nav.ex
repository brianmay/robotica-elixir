defmodule RoboticaUi.Components.Nav do
  @moduledoc false

  use Scenic.Component

  alias Scenic.Graph

  import Scenic.Primitives
  import Scenic.Clock.Components

  def verify(tab) when is_atom(tab), do: {:ok, tab}
  def verify(_), do: :invalid_data

  # build the path to the static asset file (compile time)
  @timezone Application.get_env(:robotica_plugins, :timezone)
  @schedule_path :code.priv_dir(:robotica_ui) |> Path.join("/static/images/schedule.png")
  @local_path :code.priv_dir(:robotica_ui) |> Path.join("/static/images/local.png")

  # pre-compute the hash (compile time)
  @schedule_hash Scenic.Cache.Support.Hash.file!(@schedule_path, :sha)
  @local_hash Scenic.Cache.Support.Hash.file!(@local_path, :sha)

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

  def init(tab, opts) do
    schedule_path = :code.priv_dir(:robotica_ui) |> Path.join("/static/images/schedule.png")
    local_path = :code.priv_dir(:robotica_ui) |> Path.join("/static/images/local.png")

    Scenic.Cache.Static.Texture.load(schedule_path, @schedule_hash, scope: :global)
    Scenic.Cache.Static.Texture.load(local_path, @local_hash, scope: :global)

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
      |> rect({80, 80}, fill: {:image, @schedule_hash}, translate: {10, 110})
      |> rect({80, 80}, fill: {:image, @local_hash}, translate: {10, 210})

    {:ok, %{graph: graph, viewport: opts[:viewport]}, push: graph}
  end

  def handle_input({:cursor_button, {:left, :press, 0, click_pos}}, _context, state) do
    scenes = Enum.filter(@scenes, fn {_, icon_pos} -> in_bounding_box(click_pos, icon_pos) end)

    case scenes do
      [{tab, _} | _] -> RoboticaUi.RootManager.set_tab(tab)
      _ -> nil
    end

    RoboticaUi.RootManager.reset_screensaver()
    {:noreply, state}
  end

  def handle_input(_event, _context, state) do
    RoboticaUi.RootManager.reset_screensaver()
    {:noreply, state}
  end
end
