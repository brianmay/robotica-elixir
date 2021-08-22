defmodule RoboticaUi.Scene.Schedule do
  @moduledoc false
  use Scenic.Scene
  use RoboticaCommon.EventBus
  require Logger

  alias Scenic.Graph
  alias Scenic.ViewPort
  import Scenic.Primitives

  alias RoboticaCommon.Config
  alias RoboticaCommon.Schema
  alias RoboticaUi.Components.Marks
  alias RoboticaUi.Components.Nav
  alias RoboticaUi.Components.Step
  alias RoboticaUi.Layout

  @graph Graph.build(font: :roboto, font_size: 24)

  # ============================================================================
  # setup

  # --------------------------------------------------------
  def init(_, opts) do
    schedule_host = Config.ui_schedule_host()

    RoboticaCommon.EventBus.notify(:subscribe, %{
      topic: ["schedule", schedule_host],
      label: :schedule,
      pid: self(),
      format: :json,
      resend: :resend
    })

    schedule = []
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
          step.tasks
          |> Enum.filter(fn task ->
            Enum.any?(task.locations, &(&1 == local_location))
          end)
          |> Enum.map(fn task ->
            %{task | locations: [local_location]}
          end)

        %RoboticaCommon.ScheduledStep{step | tasks: tasks}
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

  def handle_cast({:mqtt, _, :schedule, schedule}, state) do
    case Schema.validate_scheduled_steps(schedule) do
      {:ok, steps} ->
        graph =
          state.empty_graph
          |> update_schedule(steps, state.width)

        {:noreply, %{state | graph: graph}, push: graph}

      {:error, reason} ->
        Logger.error("Invalid schedule message received: #{inspect(reason)}.")
        {:noreply, state}
    end
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
