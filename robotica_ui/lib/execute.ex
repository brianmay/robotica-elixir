defmodule RoboticaUi.Execute do
  @moduledoc false

  use GenServer
  require Logger

  defmodule State do
    @type t :: %__MODULE__{
            timer: pid()
          }
    defstruct [:timer]
  end

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def init(_opts) do
    {:ok, %State{}}
  end

  def execute(task) do
    GenServer.cast(__MODULE__, {:execute, task})
  end

  def update_message(state, text) do
    case state.timer do
      nil ->
        nil

      timer ->
        Process.cancel_timer(timer)
        RoboticaUi.RootManager.set_priority_scene(nil)
    end

    timer =
      case text do
        nil ->
          nil

        text ->
          RoboticaUi.RootManager.set_priority_scene({RoboticaUi.Scene.Message, text: text})
          Process.send_after(self(), :timer, 10_000)
      end

    %{state | timer: timer}
  end

  def handle_cast({:execute, task}, state) do
    location = RoboticaPlugins.Config.ui_default_location()

    good_location = Enum.any?(task.locations, fn l -> l == location end)
    message = RoboticaPlugins.Action.action_to_message(task.action)

    state =
      case {good_location, message} do
        {false, _} -> state
        {_, nil} -> state
        {_, text} -> update_message(state, text)
      end

    {:noreply, state}
  end

  def handle_info(:timer, state) do
    RoboticaUi.RootManager.set_priority_scene(nil)
    state = %{state | timer: nil}
    {:noreply, state}
  end
end
