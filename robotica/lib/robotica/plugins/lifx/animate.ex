defmodule Robotica.Plugins.Lifx.Animate do
  @moduledoc """
  Lifx animation
  """
  alias Robotica.Devices.Lifx, as: RLifx
  require Logger

  alias Robotica.Devices.Lifx.HSBKA

  @type hsbkas :: {integer(), list(HSBKA.t()), integer()}

  @spec animate(map(), integer()) :: list(hsbkas)
  defp animate(animation, number) do
    animate_frames(animation.frames, number)
  end

  @spec animate_frames(list(), integer()) :: list(hsbkas)
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

  @spec animate_frame_repeat(map(), integer(), integer(), integer()) :: list(hsbkas)
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

  @spec animate_repeat(RLifx.callback(), list(hsbkas), integer | nil, integer) :: :ok
  defp animate_repeat(_, _, repeat_count, repeat_n)
       when not is_nil(repeat_count) and repeat_n >= repeat_count do
    :ok
  end

  defp animate_repeat(sender, list_hsbkas, repeat_count, repeat_n) do
    Enum.each(list_hsbkas, fn hsbkas ->
      {power, colors, sleep} = hsbkas
      sender.(power, colors)
      Process.sleep(sleep)
    end)

    animate_repeat(sender, list_hsbkas, repeat_count, repeat_n + 1)
  end

  @spec go(RLifx.callback(), integer(), map()) :: :ok
  def go(sender, number, animation) do
    repeat_count =
      case animation.frames do
        [] -> 0
        _ -> animation.repeat
      end

    list_hsbks = animate(animation, number)
    animate_repeat(sender, list_hsbks, repeat_count, 0)
  end
end
