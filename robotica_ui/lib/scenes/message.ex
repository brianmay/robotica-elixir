defmodule RoboticaUi.Scene.Message do
  @moduledoc false

  use Scenic.Scene

  alias Scenic.Graph
  alias Scenic.ViewPort
  import Scenic.Primitives

  alias RoboticaUi.Layout

  @graph Graph.build(font: :roboto, font_size: 36)

  # ============================================================================
  # setup

  # --------------------------------------------------------
  def init(scene, params, _opts) do
    message = Keyword.get(params, :text)

    viewport = scene.viewport
    {:ok, %{size: {vp_width, vp_height}}} = ViewPort.info(viewport)

    x = vp_width / 2
    y = vp_height / 2

    graph =
      @graph
      |> Layout.add_background(vp_width, vp_height)
      |> text(message, id: :text, text_align: :center, translate: {x, y})

    scene = push_graph(scene, graph)
    :ok = request_input(scene, :cursor_button)
    :ok = request_input(scene, :key)
    {:ok, scene}
  end

  def handle_input(_event, _context, scene) do
    RoboticaUi.RootManager.reset_screensaver()
    RoboticaUi.RootManager.set_priority_scene(nil)
    {:noreply, scene}
  end
end
