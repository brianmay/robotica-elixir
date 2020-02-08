defmodule RoboticaUi.Scene.Remote do
  use Scenic.Scene
  use EventBus.EventSource

  alias Scenic.Graph
  alias Scenic.ViewPort
  import Scenic.Primitives

  alias RoboticaUi.Layout
  import RoboticaUi.Scene.Utils
  alias RoboticaUi.Components.Nav

  @graph Graph.build(font: :roboto, font_size: 24)

  # ============================================================================
  # setup

  # --------------------------------------------------------
  def init(_, opts) do
    viewport = opts[:viewport]
    {:ok, %ViewPort.Status{size: {vp_width, vp_height}}} = ViewPort.info(viewport)

    configuration = RoboticaPlugins.Config.ui_configuration()
    remote_locations = configuration.remote_locations
    rows = configuration.remote_buttons

    graph =
      @graph
      |> Layout.add_background(vp_width, vp_height)
      |> add_text("Locations", 0, 0)

    {graph, _} =
      Enum.reduce(remote_locations, {graph, 1}, fn location, {graph, x} ->
        id_false = {:location, location, false}
        id_true = {:location, location, true}

        graph =
          graph
          |> add_button(location, id_false, x, 0, theme: :primary, hidden: false)
          |> add_button(location, id_true, x, 0, theme: :danger, hidden: true)

        {graph, x + 1}
      end)

    {graph, _} =
      Enum.reduce(rows, {graph, 1}, fn row, {graph, y} ->
        graph = add_text(graph, row.name, 0, y)

        {graph, _} =
          Enum.reduce(row.buttons, {graph, 1}, fn button, {graph, x} ->
            id = {:action, button.devices, button.action}

            graph = add_button(graph, button.name, id, x, y, theme: :primary)

            {graph, x + 1}
          end)

        {graph, y + 1}
      end)

    graph = Nav.add_to_graph(graph, :remote)

    {:ok, %{locations: MapSet.new(), remote_locations: remote_locations, graph: graph},
     push: graph}
  end

  def handle_input(_event, _context, state) do
    RoboticaUi.RootManager.reset_screensaver()
    {:noreply, state}
  end

  def filter_event({:click, button}, _, state) do
    RoboticaUi.RootManager.reset_screensaver()

    state =
      case button do
        {:location, location, value} ->
          handle_location_press(location, state, value)

        {:action, devices, action} ->
          handle_action_press(action, devices, state)

        _ ->
          state
      end

    {:halt, state, push: state.graph}
  end

  def handle_location_press(location, state, value) do
    locations = state.locations
    graph = state.graph

    locations =
      case value do
        true -> MapSet.delete(locations, location)
        false -> MapSet.put(locations, location)
      end

    graph =
      Enum.reduce(state.remote_locations, graph, fn location, graph ->
        value = MapSet.member?(locations, location)

        id_false = {:location, location, false}
        id_true = {:location, location, true}

        graph
        |> Graph.modify(id_false, &update_opts(&1, hidden: value != false))
        |> Graph.modify(id_true, &update_opts(&1, hidden: value != true))
      end)

    %{state | locations: locations, graph: graph}
  end

  def handle_action_press(action, devices, state) do
    event_params = %{topic: :remote_execute}

    EventSource.notify event_params do
      %RoboticaPlugins.Task{
        locations: MapSet.to_list(state.locations),
        devices: devices,
        action: action
      }
    end

    state
  end
end
