defmodule RoboticaUi.Scene.Schedule do
  @moduledoc false
  use Scenic.Scene
  use RoboticaCommon.EventBus
  require Logger

  alias Scenic.Graph
  alias Scenic.ViewPort
  import Scenic.Primitives

  alias Robotica.CommonConfig
  alias Robotica.Schema
  alias RoboticaUi.Components.Marks
  alias RoboticaUi.Components.Nav
  alias RoboticaUi.Components.Step
  alias RoboticaUi.Layout

  @graph Graph.build(font: :roboto, font_size: 16)

  # ============================================================================
  # setup

  # --------------------------------------------------------
  def init(scene, _, _opts) do
    schedule_host = CommonConfig.ui_schedule_hostname()

    RoboticaCommon.EventBus.notify(:subscribe, %{
      topic: "schedule/#{schedule_host}",
      label: :schedule,
      pid: self(),
      format: :json,
      resend: :resend
    })

    schedule = []
    {:ok, %{size: {vp_width, vp_height}}} = ViewPort.info(scene.viewport)

    empty_graph =
      @graph
      |> Layout.add_background(vp_width, vp_height)
      |> text("Time", text_align: :left, translate: {110, 30})
      |> text("Step", text_align: :left, translate: {210, 30})
      |> Nav.add_to_graph(:schedule)

    graph =
      empty_graph
      |> update_schedule(schedule, vp_width)

    scene =
      scene
      |> assign(graph: graph, empty_graph: empty_graph, width: vp_width, height: vp_height)
      |> push_graph(graph)

    :ok = request_input(scene, :cursor_button)
    :ok = request_input(scene, :key)

    {:ok, scene}
  end

  def handle_input(_event, _context, scene) do
    RoboticaUi.RootManager.reset_screensaver()
    {:noreply, scene}
  end

  defp update_schedule(graph, steps, width) do
    local_location = CommonConfig.ui_default_location()

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

        %Robotica.Types.ScheduledStep{step | tasks: tasks}
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

  def handle_cast({:mqtt, _, :schedule, schedule}, scene) do
    case Schema.validate_scheduled_steps(schedule) do
      {:ok, steps} ->
        graph =
          scene.assigns.empty_graph
          |> update_schedule(steps, scene.assigns.width)

        scene =
          scene
          |> assign(graph: graph)
          |> push_graph(graph)

        {:noreply, scene}

      {:error, reason} ->
        Logger.error("Invalid schedule message received: #{inspect(reason)}.")
        {:noreply, scene}
    end
  end

  def handle_event({:click, step}, _, scene) do
    graph =
      @graph
      |> Marks.add_to_graph(step,
        translate: {10, 10},
        width: scene.assigns.width - 20,
        height: scene.assigns.height - 20
      )

    scene = push_graph(scene, graph)
    {:halt, scene}
  end

  def handle_event({:done, _step}, _, scene) do
    scene = push_graph(scene, scene.assigns.graph)
    {:halt, scene}
  end
end
