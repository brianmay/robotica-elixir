defmodule RoboticaUi.Scene.Utils do
  @moduledoc """
  Helper functions for scenes
  """

  import Scenic.Components
  import Scenic.Primitives

  def add_button(graph, label, id, x, y, opts \\ []) do
    x = x * 100 + 120
    y = y * 100 + 10

    styles = [font_size: 16, font: :roboto]

    button(
      graph,
      label,
      [id: id, translate: {x, y}, width: 80, height: 80, styles: styles] ++ opts
    )
  end

  def add_text(graph, label, x, y, opts \\ []) do
    x = x * 100 + 120
    y = y * 100 + 60

    text(graph, label, [translate: {x, y}, width: 80, height: 80] ++ opts)
  end
end
