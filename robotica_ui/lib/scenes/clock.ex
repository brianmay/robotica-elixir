defmodule RoboticaUi.Scene.Clock do
  @moduledoc false

  use Scenic.Scene

  alias Scenic.Graph
  alias Scenic.ViewPort
  import Scenic.Clock.Components

  alias RoboticaUi.Components.Nav
  alias RoboticaUi.Layout

  @timezone Application.compile_env(:robotica_common, :timezone)

  @graph Graph.build(font: :roboto, font_size: 24)

  # ============================================================================
  # setup

  # --------------------------------------------------------
  def init(scene, _, _opts) do
    viewport = scene.viewport
    {:ok, %{size: {vp_width, vp_height}}} = ViewPort.info(viewport)

    ul_margin_x = 110
    ul_margin_y = 10

    lr_margin_x = 250
    lr_margin_y = 10

    width = vp_width - ul_margin_x - lr_margin_x
    height = vp_height - ul_margin_y - lr_margin_y

    radius = Enum.min_by([width, height], fn x -> x end) / 2

    centre_x = ul_margin_x + radius
    centre_y = ul_margin_y + radius

    graph =
      @graph
      |> Layout.add_background(vp_width, vp_height)
      |> digital_clock(translate: {vp_width - lr_margin_x, 50}, timezone: @timezone)
      |> analog_clock(
        radius: radius,
        translate: {centre_x, centre_y},
        timezone: @timezone,
        seconds: true
      )
      |> Nav.add_to_graph(:clock)

    scene = push_graph(scene, graph)
    :ok = request_input(scene, :cursor_button)
    :ok = request_input(scene, :key)
    {:ok, scene}
  end

  def handle_input(_event, _context, scene) do
    RoboticaUi.RootManager.reset_screensaver()
    {:noreply, scene}
  end

  def handle_event({:click, _button}, _, scene) do
    RoboticaUi.RootManager.reset_screensaver()

    {:halt, scene}
  end
end
