defmodule RoboticaUi.Scene.Local do
  @moduledoc false

  use Scenic.Scene
  use EventBus.EventSource

  alias Scenic.Graph
  alias Scenic.ViewPort
  import Scenic.Primitives

  alias RoboticaCommon.Config
  alias RoboticaUi.Layout
  import RoboticaUi.Scene.Utils
  alias RoboticaUi.Components.Nav

  require Logger

  @graph Graph.build(font: :roboto, font_size: 24)

  # ============================================================================
  # setup

  # --------------------------------------------------------
  def init(_, opts) do
    viewport = opts[:viewport]
    {:ok, %ViewPort.Status{size: {vp_width, vp_height}}} = ViewPort.info(viewport)

    graph = @graph
    location = Config.ui_default_location()
    buttons = Config.ui_local_buttons(location)

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
          RoboticaCommon.Buttons.subscribe_topics(button)
          Map.put(buttons, button.id, button)
        end)
      end)

    button_states =
      Enum.reduce(buttons, %{}, fn {id, button}, button_states ->
        RoboticaCommon.Buttons.subscribe_topics(button)
        Map.put(button_states, id, RoboticaCommon.Buttons.get_initial_state(button))
      end)

    graph = Nav.add_to_graph(graph, :local)

    {:ok, %{location: location, buttons: buttons, button_states: button_states, graph: graph},
     push: graph}
  end

  def handle_cast({:mqtt, _, {button_id, label}, data}, state) do
    state =
      case Map.get(state.buttons, button_id) do
        nil ->
          Logger.error("Unknown button #{button_id}")
          state

        button ->
          button_state = Map.get(state.button_states, button_id)

          button_state = RoboticaCommon.Buttons.process_message(button, label, data, button_state)

          button_states = Map.put(state.button_states, button_id, button_state)

          display_state = RoboticaCommon.Buttons.get_display_state(button, button_state)

          controls = [:state_on, :state_off, :state_hard_off, :state_error, nil]

          graph =
            Enum.reduce(controls, state.graph, fn control, graph ->
              Graph.modify(
                graph,
                {control, button_id},
                &update_opts(&1, hidden: display_state != control)
              )
            end)

          %{state | button_states: button_states, graph: graph}
      end

    {:noreply, state, push: state.graph}
  end

  def handle_input(_event, _context, state) do
    RoboticaUi.RootManager.reset_screensaver()
    {:noreply, state}
  end

  def filter_event({:click, button}, _, state) do
    RoboticaUi.RootManager.reset_screensaver()

    state =
      case button do
        {_, button_id} ->
          handle_command_press(button_id, state)

        _ ->
          state
      end

    {:halt, state, push: state.graph}
  end

  def handle_command_press(button_id, state) do
    button = Map.get(state.buttons, button_id)
    Logger.info("robotica_ui: Got button press #{button.name}")

    case button do
      nil ->
        Logger.error("Unknown button #{inspect(button_id)}")

      button ->
        button_state = Map.get(state.button_states, button_id)
        RoboticaCommon.Buttons.execute_press_commands(button, button_state)
    end

    state
  end
end
