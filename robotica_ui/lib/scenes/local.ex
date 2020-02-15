defmodule RoboticaUi.Scene.Local do
  use Scenic.Scene
  use EventBus.EventSource

  alias Scenic.Graph
  alias Scenic.ViewPort

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

    graph = @graph
    configuration = RoboticaPlugins.Config.ui_configuration()
    local_location = configuration.local_location
    rows = configuration.local_buttons

    graph = Layout.add_background(graph, vp_width, vp_height)

    {graph, _} =
      Enum.reduce(rows, {graph, 0}, fn row, {graph, y} ->
        graph = add_text(graph, row.name, 0, y)

        {graph, _} =
          Enum.reduce(row.buttons, {graph, 1}, fn button, {graph, x} ->
            id = {:action, button.tasks}

            graph = add_button(graph, button.name, id, x, y, theme: :primary)

            {graph, x + 1}
          end)

        {graph, y + 1}
      end)

    graph = Nav.add_to_graph(graph, :local)
    {:ok, %{location: local_location, graph: graph}, push: graph}
  end

  def handle_input(_event, _context, state) do
    RoboticaUi.RootManager.reset_screensaver()
    {:noreply, state}
  end

  def filter_event({:click, button}, _, state) do
    RoboticaUi.RootManager.reset_screensaver()

    state =
      case button do
        {:action, tasks} ->
          handle_action_press(tasks, state)

        _ ->
          state
      end

    {:halt, state, push: state.graph}
  end

  def handle_action_press(tasks, state) do
    event_params = %{topic: :remote_execute}

    Enum.each(tasks, fn task ->
      locations =
        case task.locations do
          nil -> [state.location]
          locations -> locations
        end

      EventSource.notify event_params do
        %RoboticaPlugins.Task{
          locations: locations,
          devices: task.devices,
          action: task.action
        }
      end
    end)

    state
  end
end
