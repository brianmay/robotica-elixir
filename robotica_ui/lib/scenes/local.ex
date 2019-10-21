defmodule RoboticaUi.Scene.Local do
  use Scenic.Scene
  use EventBus.EventSource

  alias Scenic.Graph
  alias Scenic.ViewPort
  import Scenic.Primitives

  alias RoboticaUi.Layout
  import RoboticaUi.Scene.Utils
  alias RoboticaUi.Components.Nav

  @graph Graph.build(font: :roboto, font_size: 24)
         |> rect({800, 480}, fill: {:black, 0})

  # ============================================================================
  # setup

  # --------------------------------------------------------
  def init(_, opts) do
    viewport = opts[:viewport]
    {:ok, %ViewPort.Status{size: {vp_width, vp_height}}} = ViewPort.info(viewport)

    graph = @graph
    configuration = RoboticaUi.Config.configuration()
    local_locations = configuration.local_locations
    rows = configuration.local_buttons

    graph = Layout.add_background(graph, vp_width, vp_height)

    {graph, _} =
      Enum.reduce(rows, {graph, 0}, fn row, {graph, y} ->
        graph = add_text(graph, row.name, 0, y)

        {graph, _} =
          Enum.reduce(row.buttons, {graph, 1}, fn button, {graph, x} ->
            id = {:action, button.action}

            graph = add_button(graph, button.name, id, x, y, theme: :primary)

            {graph, x + 1}
          end)

        {graph, y + 1}
      end)

    graph = Nav.add_to_graph(graph, :local)
    {:ok, %{locations: local_locations, graph: graph}, push: graph}
  end

  def handle_input(_event, _context, state) do
    RoboticaUi.RootManager.reset_screensaver()
    {:noreply, state}
  end

  def filter_event({:click, button}, _, state) do
    RoboticaUi.RootManager.reset_screensaver()

    state =
      case button do
        {:action, action} ->
          handle_action_press(action, state)

        _ ->
          state
      end

    {:halt, state, push: state.graph}
  end

  def handle_action_press(action, state) do
    event_params = %{topic: :local_execute}

    EventSource.notify event_params do
      %RoboticaPlugins.Task{
        locations: state.locations,
        action: action
      }
    end

    state
  end
end
