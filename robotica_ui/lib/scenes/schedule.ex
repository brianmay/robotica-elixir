defmodule RoboticaUi.Scene.Schedule do
  use Scenic.Scene
  use EventBus.EventSource
  require Logger

  alias Scenic.Graph
  alias Scenic.ViewPort
  import Scenic.Primitives

  alias RoboticaPlugins.Config
  alias RoboticaUi.Layout
  alias RoboticaUi.Components.Nav
  alias RoboticaUi.Components.Step
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
      |> text("Step", text_align: :left, translate: {210, 30})
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
    local_location = Config.ui_default_location()

    steps =
      steps
      |> Enum.map(fn step ->
        tasks =
          Enum.filter(step.tasks, fn task ->
            Enum.any?(task.locations, &(&1 == local_location))
          end)

        %RoboticaPlugins.ScheduledStep{step | tasks: tasks}
      end)
      |> Enum.reject(fn step -> Enum.empty?(step.tasks) end)
      |> Enum.take(20)

    graph
    |> group(fn graph ->
      {graph, _} =
        Enum.reduce(steps, {graph, 0}, fn step, {graph, y} ->
          graph =
            graph
            |> Step.add_to_graph(step, translate: {100, y * 40 + 40}, width: width - 100)

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
