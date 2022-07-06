defmodule RoboticaUi.Execute do
  @moduledoc """
  Receive and distribute execute events
  """

  use GenServer
  use RoboticaCommon.EventBus
  require Logger

  alias Robotica.CommonConfig

  defmodule State do
    @moduledoc false
    @type t :: %__MODULE__{
            timer: pid()
          }
    defstruct [:timer]
  end

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def init(_opts) do
    local_location = CommonConfig.ui_default_location()

    RoboticaCommon.EventBus.notify(:subscribe, %{
      topic: ["action", local_location, "Robotica"],
      label: :action,
      pid: self(),
      format: :json,
      resend: :no_resend
    })

    {:ok, %State{}}
  end

  def command_task(task) do
    GenServer.cast(__MODULE__, {:command_task, task})
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

  def handle_cast({:mqtt, _, :action, command}, state) do
    message = get_in(command, ["message", "text"])

    state =
      case message do
        nil -> state
        text -> update_message(state, text)
      end

    {:noreply, state}
  end

  def handle_info(:timer, state) do
    RoboticaUi.RootManager.set_priority_scene(nil)
    state = %{state | timer: nil}
    {:noreply, state}
  end
end
