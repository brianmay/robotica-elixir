defmodule RoboticaUi.Layout do
  import Scenic.Primitives

  def add_background(graph, vp_width, vp_height) do
    rect(graph, {vp_width - 100, vp_height}, fill: :black, translate: {100, 0})
  end
end
