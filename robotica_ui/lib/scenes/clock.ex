defmodule RoboticaUi.Scene.Clock do
  use Scenic.Scene

  alias Scenic.Graph
  alias Scenic.ViewPort
  import Scenic.Clock.Components

  alias RoboticaUi.Layout
  alias RoboticaUi.Components.Nav

  @timezone Application.get_env(:robotica_common, :timezone)

  @graph Graph.build(font: :roboto, font_size: 24)

  # ============================================================================
  # setup

  # --------------------------------------------------------
  def init(_, opts) do
    viewport = opts[:viewport]
    {:ok, %ViewPort.Status{size: {vp_width, vp_height}}} = ViewPort.info(viewport)

    ul_margin_x = 150
    ul_margin_y = 75

    lr_margin_x = 10
    lr_margin_y = 10

    width = vp_width - ul_margin_x - lr_margin_x
    height = vp_height - ul_margin_y - lr_margin_y

    radius = Enum.min_by([width, height], fn x -> x end) / 2

    centre_x = ul_margin_x + radius
    centre_y = ul_margin_y + radius

    graph =
      @graph
      |> Layout.add_background(vp_width, vp_height)
      |> digital_clock(translate: {ul_margin_x, 50}, timezone: @timezone)
      |> analog_clock(
        radius: radius,
        translate: {centre_x, centre_y},
        timezone: @timezone,
        seconds: true
      )
      |> Nav.add_to_graph(:clock)

    {:ok, %{}, push: graph}
  end

  def handle_input(_event, _context, state) do
    RoboticaUi.RootManager.reset_screensaver()
    {:noreply, state}
  end

  def filter_event({:click, _button}, _, state) do
    RoboticaUi.RootManager.reset_screensaver()

    {:halt, state}
  end
end
