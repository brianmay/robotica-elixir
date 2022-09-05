defmodule RoboticaUi.Scene.Local do
  @moduledoc false

  use Scenic.Scene
  use EventBus.EventSource

  alias Scenic.Graph
  alias Scenic.ViewPort
  import Scenic.Primitives

  alias Robotica.CommonConfig
  alias RoboticaUi.Layout
  import RoboticaUi.Scene.Utils
  alias RoboticaUi.Components.Nav

  require Logger

  @graph Graph.build(font: :roboto, font_size: 16)

  # ============================================================================
  # setup

  # --------------------------------------------------------
  def init(scene, _, _opts) do
    viewport = scene.viewport
    {:ok, %{size: {vp_width, vp_height}}} = ViewPort.info(viewport)

    graph = @graph
    location = CommonConfig.ui_default_location()
    buttons = CommonConfig.ui_local_buttons(location)

    graph = Layout.add_background(graph, vp_width, vp_height)

    {graph, _} =
      Enum.reduce(buttons, {graph, 0}, fn row, {graph, y} ->
        graph = add_text(graph, row.name, 0, y)

        {graph, _} =
          Enum.reduce(row.buttons, {graph, 1}, fn button, {graph, x} ->
            graph =
              add_button(graph, button.name, {:state_on, button.id}, x, y,
                theme: :success,
                hidden: true
              )

            graph =
              add_button(graph, button.name, {:state_off, button.id}, x, y,
                theme: :primary,
                hidden: true
              )

            graph =
              add_button(graph, button.name, {:state_hard_off, button.id}, x, y,
                theme: :dark,
                hidden: true
              )

            graph =
              add_button(graph, button.name, {:state_error, button.id}, x, y,
                theme: :danger,
                hidden: true
              )

            graph =
              add_button(graph, button.name, {nil, button.id}, x, y,
                theme: :secondary,
                hidden: false
              )

            {graph, x + 1}
          end)

        {graph, y + 1}
      end)

    buttons =
      Enum.reduce(buttons, %{}, fn row, buttons ->
        Enum.reduce(row.buttons, buttons, fn button, buttons ->
          Robotica.Buttons.subscribe_topics(button)
          Map.put(buttons, button.id, button)
        end)
      end)

    button_states =
      Enum.reduce(buttons, %{}, fn {id, button}, button_states ->
        Robotica.Buttons.subscribe_topics(button)
        Map.put(button_states, id, Robotica.Buttons.get_initial_state(button))
      end)

    graph = Nav.add_to_graph(graph, :local)

    scene =
      scene
      |> assign(location: location, buttons: buttons, button_states: button_states, graph: graph)
      |> push_graph(graph)

    :ok = request_input(scene, :cursor_button)
    :ok = request_input(scene, :key)
    {:ok, scene}
  end

  def handle_cast({:mqtt, _, {button_id, label}, data}, scene) do
    scene =
      case Map.get(scene.assigns.buttons, button_id) do
        nil ->
          Logger.error("Unknown button #{button_id}")
          scene

        button ->
          button_state = Map.get(scene.assigns.button_states, button_id)

          button_state = Robotica.Buttons.process_message(button, label, data, button_state)

          button_states = Map.put(scene.assigns.button_states, button_id, button_state)

          display_state = Robotica.Buttons.get_display_state(button, button_state)

          controls = [:state_on, :state_off, :state_hard_off, :state_error, nil]

          graph =
            Enum.reduce(controls, scene.assigns.graph, fn control, graph ->
              Graph.modify(
                graph,
                {control, button_id},
                &update_opts(&1, hidden: display_state != control)
              )
            end)

          scene
          |> assign(button_states: button_states, graph: graph)
          |> push_graph(graph)
      end

    {:noreply, scene}
  end

  def handle_input(_event, _context, scene) do
    RoboticaUi.RootManager.reset_screensaver()
    {:noreply, scene}
  end

  def handle_event({:click, button}, _, scene) do
    RoboticaUi.RootManager.reset_screensaver()

    scene =
      case button do
        {_, button_id} ->
          handle_command_press(button_id, scene)

        _ ->
          scene
      end

    {:halt, scene}
  end

  def handle_command_press(button_id, scene) do
    button = Map.get(scene.assigns.buttons, button_id)
    Logger.info("robotica_ui: Got button press #{button.name}")

    case button do
      nil ->
        Logger.error("Unknown button #{inspect(button_id)}")

      button ->
        button_state = Map.get(scene.assigns.button_states, button_id)
        Robotica.Buttons.execute_press_commands(button, button_state)
    end

    scene
  end
end
