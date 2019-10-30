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

  def execute(action) do
    GenServer.cast(__MODULE__, {:execute, action})
  end

  def update_message(state, text) do
    case state.timer do
      nil ->
        nil

      timer ->
        Process.cancel_timer(timer)
        RoboticaUi.RootManager.set_scene(:message, nil)
    end

    timer =
      case text do
        nil ->
          nil

        text ->
          RoboticaUi.RootManager.set_scene(:message, {RoboticaUi.Scene.Message, text: text})
          Process.send_after(self(), :timer, 10_000)
      end

    state = %{state | timer: timer}
    {:noreply, state}
  end

  def handle_info(:timer, state) do
    RoboticaUi.RootManager.set_scene(:message, nil)
    state = %{state | timer: nil}
    {:noreply, state}
  end
end
