defmodule Robotica.Plugins.Lifx.Animate do
  @moduledoc """
  Lifx animation
  """
  use GenServer

  alias Robotica.Devices.Lifx, as: RLifx
  require Logger

  alias Robotica.Devices.Lifx.HSBKA
  @type hsbkas_t :: {integer(), list(HSBKA.t()), integer()}

  defmodule Options do
    @moduledoc """
    Options for Animate animation
    """
    @type t :: %__MODULE__{
            sender: RLifx.callback(),
            number: integer(),
            animation: map()
          }
    @enforce_keys [:sender, :number, :animation]
    defstruct @enforce_keys
  end

  defmodule State do
    @moduledoc false
    @type t :: %__MODULE__{
            options: Options.t(),
            initial_list: list(Robotica.Plugins.Lifx.Animate.hsbkas_t()),
            list: list(Robotica.Plugins.Lifx.Animate.hsbkas_t()),
            repeat: integer() | nil
          }
    @enforce_keys [:options, :initial_list, :list, :repeat]
    defstruct @enforce_keys
  end

  def start(%Options{} = options) do
    GenServer.start(__MODULE__, options)
  end

  @impl true
  def init(%Options{} = options) do
    list = animate(options.animation, options.number)

    state = %State{
      options: options,
      list: list,
      initial_list: list,
      repeat: options.animation.repeat
    }

    Process.send_after(self(), :timer, 0)
    {:ok, state}
  end

  @impl true
  def handle_info(:timer, %State{list: [], repeat: repeat} = state) do
    new_repeat =
      case repeat do
        nil -> nil
        n -> n - 1
      end

    state = %State{state | list: state.initial_list, repeat: new_repeat}
    handle_info(:timer, state)
  end

  @impl true
  def handle_info(:timer, %State{list: [head | tail]} = state) do
    {power, colors, sleep} = head

    state.options.sender.(power, colors)
    Process.send_after(self(), :timer, sleep)

    state = %State{state | list: tail}
    {:noreply, state}
  end

  @impl true
  def handle_cast(:stop, %State{} = state) do
    {:stop, :normal, state}
  end

  @spec animate(map(), integer()) :: list(hsbkas_t)
  defp animate(animation, number) do
    animate_frames(animation.frames, number)
  end

  @spec animate_frames(list(), integer()) :: list(hsbkas_t)
  defp animate_frames([], _), do: []

  defp animate_frames([frame | tail], number) do
    frame_count =
      case frame.repeat do
        nil -> 1
        frame_count -> frame_count
      end

    head = animate_frame_repeat(frame, number, frame_count, 0)
    tail = animate_frames(tail, number)
    head ++ tail
  end

  @spec animate_frame_repeat(map(), integer(), integer(), integer()) :: list(hsbkas_t)
  defp animate_frame_repeat(_, _, frame_count, frame_n) when frame_n >= frame_count do
    []
  end

  defp animate_frame_repeat(frame, number, frame_count, frame_n) do
    case RLifx.get_colors_from_command(number, frame, frame_n) do
      {:ok, colors} ->
        hsbks = {65_535, colors, frame.sleep}
        [hsbks | animate_frame_repeat(frame, number, frame_count, frame_n + 1)]

      {:error, error} ->
        Logger.error("Got error in lifx get_colors_from_command: #{inspect(error)}")
        animate_frame_repeat(frame, number, frame_count, frame_n + 1)
    end
  end
end
