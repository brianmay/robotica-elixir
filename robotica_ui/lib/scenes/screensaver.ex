defmodule RoboticaUi.Scene.Screensaver do
  @moduledoc false

  use Scenic.Scene

  alias Scenic.Graph
  alias Scenic.ViewPort
  import Scenic.Primitives

  @graph Graph.build(font: :roboto, font_size: 24)

  # ============================================================================
  # setup

  # --------------------------------------------------------
  def init(scene, _, _opts) do
    message = "The screen is off"

    viewport = scene.viewport
    {:ok, %{size: {vp_width, vp_height}}} = ViewPort.info(viewport)

    x = vp_width / 2
    y = vp_height / 2

    graph =
      @graph
      |> rect({vp_width, vp_height}, fill: :black)
      |> text(message, id: :text, text_align: :center, translate: {x, y})

    scene = push_graph(scene, graph)

    :ok = request_input(scene, :cursor_button)
    :ok = request_input(scene, :key)
    {:ok, scene}
  end

  def handle_input({:cursor_button, {_, 1, _, _}}, _, scene) do
    # Ignore button presses, only reset screen saver on releases.
    {:noreply, scene}
  end

  def handle_input(_event, _, scene) do
    RoboticaUi.RootManager.reset_screensaver()
    {:noreply, scene}
  end
end
