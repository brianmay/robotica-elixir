defmodule RoboticaUi.RootManager do
  @moduledoc false
  require Logger

  use GenServer

  alias Scenic.ViewPort

  defmodule Scenes do
    @type t :: %__MODULE__{
            message: atom() | {atom(), any()} | nil
          }
    defstruct [:message]
  end

  defmodule Tabs do
    @type t :: %__MODULE__{
            clock: atom() | {atom(), any()} | nil,
            schedule: atom() | {atom(), any()} | nil,
            local: atom() | {atom(), any()} | nil
          }
    defstruct [:clock, :schedule, :local]
  end

  defmodule State do
    @type t :: %__MODULE__{
            scenes: Scenes.t(),
            tabs: Tabs.t(),
            tab: :clock | :schedule | :local,
            timer: reference() | nil,
            priority_scene: atom() | {atom(), any()} | nil
          }
    defstruct scenes: %Scenes{},
              tabs: %Tabs{
                clock: {RoboticaUi.Scene.Clock, nil},
                schedule: {RoboticaUi.Scene.Schedule, nil},
                local: {RoboticaUi.Scene.Local, nil}
              },
              tab: :clock,
              timer: nil,
              priority_scene: nil
  end

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    state = reset_timer(%State{})
    {:ok, state}
  end

  @spec set_priority_scene(atom() | {atom(), any()} | nil) :: nil
  def set_priority_scene(scene) do
    GenServer.cast(__MODULE__, {:set_priority_scene, scene})
  end

  @spec set_tab_scene(:clock | :schedule | :local, atom() | {atom(), any()} | nil) ::
          nil
  def set_tab_scene(id, scene) do
    GenServer.cast(__MODULE__, {:set_tab_scene, id, scene})
  end

  @spec set_tab(:clock | :schedule | :local) :: nil
  def set_tab(id) do
    GenServer.cast(__MODULE__, {:set_tab, id})
  end

  @spec reset_screensaver :: nil
  def reset_screensaver() do
    GenServer.cast(__MODULE__, {:reset_screensaver})
  end

  # PRIVATE STUFF BELOW

  @spec screen_off?(State.t()) :: boolean()
  defp screen_off?(state) do
    is_nil(state.timer)
  end

  @spec get_current_scene(State.t()) :: atom() | {atom(), any()} | nil
  def get_current_scene(state) do
    cond do
      not is_nil(state.priority_scene) -> state.priority_scene
      screen_off?(state) -> :screen_off
      true -> Map.get(state.tabs, state.tab)
    end
  end

  @spec update_state(State.t(), (State.t() -> State.t())) :: State.t()
  def update_state(state, callback) do
    old_scene = get_current_scene(state)
    new_state = callback.(state)
    new_scene = get_current_scene(new_state)

    if old_scene != :screen_off and new_scene == :screen_off do
      screen_off()
    end

    required_scene =
      case new_scene do
        :screen_off -> {RoboticaUi.Scene.Screensaver, nil}
        new_scene -> new_scene
      end

    if old_scene != new_scene do
      ViewPort.set_root(:main_viewport, required_scene)
    end

    if old_scene == :screen_off and new_scene != :screen_off do
      screen_on()
    end

    new_state
  end

  @spec reset_timer(State.t()) :: State.t()
  defp reset_timer(state) do
    Logger.info("reset_timer #{inspect(state.timer)}")

    case state.timer do
      nil -> nil
      timer -> Process.cancel_timer(timer)
    end

    timer = Process.send_after(__MODULE__, :screen_off, 30000, [])
    %State{state | timer: timer}
  end

  # Screen Control

  @spec screen_off :: nil
  defp screen_off() do
    Logger.info("screen_off")
    File.write("/sys/class/backlight/rpi_backlight/bl_power", "1")

    try do
      System.cmd("vcgencmd", ["display_power", "0"])
    rescue
      ErlangError -> nil
    end
  end

  @spec screen_on :: nil
  defp screen_on() do
    Logger.info("screen_on")
    File.write("/sys/class/backlight/rpi_backlight/bl_power", "0")

    try do
      System.cmd("vcgencmd", ["display_power", "1"])
    rescue
      ErlangError -> nil
    end
  end

  # Callback methods

  @impl true
  def handle_info(:screen_off, state) do
    Logger.info("rx screen_off")

    state =
      update_state(state, fn state ->
        Process.cancel_timer(state.timer)
        %State{state | timer: nil}
      end)

    {:noreply, state}
  end

  @impl true
  def handle_cast({:set_priority_scene, scene}, state) do
    Logger.info("rx set_priority_scene #{inspect(scene)}")

    state =
      update_state(state, fn state ->
        %State{state | priority_scene: scene}
      end)

    {:noreply, state}
  end

  @impl true
  def handle_cast({:set_tab_scene, id, scene}, state) do
    Logger.info("rx set_tab_scene #{inspect(id)} #{inspect(scene)}")

    # We update the saved state but do not update the display.
    state = %State{state | tabs: %{state.tabs | id => scene}}

    {:noreply, state}
  end

  @impl true
  def handle_cast({:set_tab, id}, state) do
    Logger.info("rx set_tab #{inspect(id)}")

    state =
      update_state(state, fn state ->
        %State{state | tab: id}
      end)

    {:noreply, state}
  end

  @impl true
  def handle_cast({:reset_screensaver}, state) do
    Logger.info("rx reset_screensaver")

    state =
      update_state(state, fn state ->
        reset_timer(state)
      end)

    {:noreply, state}
  end
end
