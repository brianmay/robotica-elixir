defmodule RoboticaUi.Scene.Schedule do
  use Scenic.Scene
  use EventBus.EventSource
  require Logger

  alias Scenic.Graph
  alias Scenic.ViewPort
  import Scenic.Primitives

  alias RoboticaUi.Layout
  alias RoboticaUi.Components.Nav
  alias RoboticaUi.Components.Task
  alias RoboticaUi.Components.Marks

  @graph Graph.build(font: :roboto, font_size: 24)

  # ============================================================================
  # setup

  # --------------------------------------------------------
  def init(_, opts) do
    RoboticaUi.Schedule.register(self())

    schedule =
      case RoboticaUi.Schedule.get_schedule() do
        {:ok, schedule} -> schedule
        {:error, _} -> []
      end

    viewport = opts[:viewport]
    {:ok, %ViewPort.Status{size: {vp_width, vp_height}}} = ViewPort.info(viewport)

    empty_graph =
      @graph
      |> Layout.add_background(vp_width, vp_height)
      |> text("Time", text_align: :left, translate: {110, 30})
      |> text("Locations", text_align: :left, translate: {210, 30})
      |> text("Message", text_align: :left, translate: {410, 30})
      |> Nav.add_to_graph(:schedule)

    graph =
      empty_graph
      |> update_schedule(schedule, vp_width)

    {:ok, %{graph: graph, empty_graph: empty_graph, width: vp_width, height: vp_height},
     push: graph}
  end

  def handle_input(_event, _context, state) do
    RoboticaUi.RootManager.reset_screensaver()
    {:noreply, state}
  end

  defp update_schedule(graph, steps, width) do
    steps =
      Enum.reduce(steps, [], fn step, steps ->
        Enum.reduce(step.tasks, steps, fn task, steps ->
          solo_step = %RoboticaPlugins.SingleStep{
            required_time: step.required_time,
            latest_time: step.latest_time,
            task: task
          }

          [solo_step | steps]
        end)
      end)
      |> Enum.reverse()
      |> Enum.take(20)

    graph
    |> group(fn graph ->
      {graph, _} =
        Enum.reduce(steps, {graph, 0}, fn solo_step, {graph, y} ->
          graph =
            graph
            |> Task.add_to_graph(solo_step, translate: {100, y * 40 + 40}, width: width - 100)

          {graph, y + 1}
        end)

      graph
    end)
    |> line({{110, 40}, {width - 10, 40}}, stroke: {1, :red})
  end

  def filter_event({:schedule, steps}, _, state) do
    graph =
      state.empty_graph
      |> update_schedule(steps, state.width)

    {:halt, %{state | graph: graph}, push: graph}
  end

  def filter_event({:click, step}, _, state) do
    graph =
      @graph
      |> Marks.add_to_graph(step,
        translate: {10, 10},
        width: state.width - 20,
        height: state.height - 20
      )

    {:halt, state, push: graph}
  end

  def filter_event({:done, _step}, _, state) do
    {:halt, state, push: state.graph}
  end
end
