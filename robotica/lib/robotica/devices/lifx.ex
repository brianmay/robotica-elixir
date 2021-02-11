defmodule Robotica.Devices.Lifx do
  @moduledoc """
  Provides LIFX support functions.
  """

  alias RoboticaPlugins.Strings

  defmodule HSBKA do
    @moduledoc "A color with alpha channel"
    @type t :: %__MODULE__{
            hue: integer(),
            saturation: integer(),
            brightness: integer(),
            kelvin: integer(),
            alpha: integer()
          }
    defstruct hue: 120,
              saturation: 100,
              brightness: 100,
              kelvin: 4000,
              alpha: 100
  end

  @type callback :: (boolean | nil, list(HSBKA | nil) -> :ok)

  @doc """
  Eval a dictionary of strings into a Lifx HSBK object.

  iex> import Robotica.Devices.Lifx
  iex> values = %{
  ...>   "frame" => 1,
  ...>   "light" => 2
  ...> }
  iex> eval_color(%{
  ...>   brightness: 100,
  ...>   hue: "{frame}*2",
  ...>   saturation: "{light}*2",
  ...>   kelvin: 3500,
  ...>   alpha: 100,
  ...> }, values)
  {:ok, %Robotica.Devices.Lifx.HSBKA{
    brightness: 100,
    hue: 2,
    saturation: 4,
    kelvin: 3500,
    alpha: 100
  }}
  """
  @spec eval_color(map(), map()) :: {:ok, HSBKA.t()} | {:error, String.t()}
  def eval_color(color, values) do
    alpha = if color.alpha == nil, do: 100, else: color.alpha

    with {:ok, brightness} <- Strings.eval_string(color.brightness, values),
         {:ok, hue} <- Strings.eval_string(color.hue, values),
         {:ok, saturation} <- Strings.eval_string(color.saturation, values),
         {:ok, kelvin} <- Strings.eval_string(color.kelvin, values),
         {:ok, alpha} <- Strings.eval_string(alpha, values) do
      color = %HSBKA{
        brightness: brightness,
        hue: hue,
        saturation: saturation,
        kelvin: kelvin,
        alpha: alpha
      }

      {:ok, color}
    else
      {:error, error} -> {:error, error}
    end
  end

  @doc """
  Expand and eval a condensed list of colors.

  iex> import Robotica.Devices.Lifx
  iex> color = %{
  ...>   brightness: 100,
  ...>   hue: "{frame}*30",
  ...>   saturation: "{light}*100",
  ...>   kelvin: 3500,
  ...>   alpha: 100,
  ...>  }
  iex> colors = [
  ...>   %{
  ...>     count: "{frame}",
  ...>     colors: [color, color]
  ...>   }
  ...> ]
  iex> expand_colors(colors, 0)
  {:ok, []}
  iex> expand_colors(colors, 1)
  {:ok, [
    %Robotica.Devices.Lifx.HSBKA{brightness: 100, hue: 30, saturation: 0, kelvin: 3500, alpha: 100},
    %Robotica.Devices.Lifx.HSBKA{brightness: 100, hue: 30, saturation: 0, kelvin: 3500, alpha: 100},
  ]}
  iex> expand_colors(colors, 2)
  {:ok, [
  %Robotica.Devices.Lifx.HSBKA{brightness: 100, hue: 60, saturation: 0, kelvin: 3500, alpha: 100},
  %Robotica.Devices.Lifx.HSBKA{brightness: 100, hue: 60, saturation: 0, kelvin: 3500, alpha: 100},
  %Robotica.Devices.Lifx.HSBKA{brightness: 100, hue: 60, saturation: 100, kelvin: 3500, alpha: 100},
  %Robotica.Devices.Lifx.HSBKA{brightness: 100, hue: 60, saturation: 100, kelvin: 3500, alpha: 100},
  ]}
  iex> expand_colors(colors, 3)
  {:ok, [
  %Robotica.Devices.Lifx.HSBKA{brightness: 100, hue: 90, saturation: 0, kelvin: 3500, alpha: 100},
  %Robotica.Devices.Lifx.HSBKA{brightness: 100, hue: 90, saturation: 0, kelvin: 3500, alpha: 100},
  %Robotica.Devices.Lifx.HSBKA{brightness: 100, hue: 90, saturation: 100, kelvin: 3500, alpha: 100},
  %Robotica.Devices.Lifx.HSBKA{brightness: 100, hue: 90, saturation: 100, kelvin: 3500, alpha: 100},
  %Robotica.Devices.Lifx.HSBKA{brightness: 100, hue: 90, saturation: 200, kelvin: 3500, alpha: 100},
  %Robotica.Devices.Lifx.HSBKA{brightness: 100, hue: 90, saturation: 200, kelvin: 3500, alpha: 100},
  ]}
  """
  def expand_colors(list, frame_n), do: loop_colors(list, frame_n, [])

  defp loop_colors([], _, result), do: {:ok, Enum.reverse(result)}

  defp loop_colors([head | tail], frame_n, result) do
    values = %{
      "frame" => frame_n
    }

    with {:ok, count} <- Strings.eval_string(head.count, values),
         {:ok, result} <- expand_repeat(head.colors, frame_n, count, 0, result) do
      loop_colors(tail, frame_n, result)
    else
      {:error, error} -> {:error, error}
    end
  end

  defp expand_repeat(_, _, count, light_n, result) when light_n >= count do
    {:ok, result}
  end

  defp expand_repeat(list, frame_n, count, light_n, result) do
    case expand_list(list, frame_n, light_n, result) do
      {:ok, result} ->
        expand_repeat(list, frame_n, count, light_n + 1, result)

      {:error, error} ->
        {:error, error}
    end
  end

  defp expand_list([], _, _, result), do: {:ok, result}

  defp expand_list([head | tail], frame_n, light_n, result) do
    values = %{
      "frame" => frame_n,
      "light" => light_n
    }

    case eval_color(head, values) do
      {:ok, color} ->
        result = [color | result]
        expand_list(tail, frame_n, light_n, result)

      {:error, error} ->
        {:error, error}
    end
  end

  @spec replicate(any(), integer()) :: list(any())
  defp replicate(x, n), do: for(i <- 0..n, i > 0, do: x)

  @spec fill_colors(list(HSBKA.t()), integer()) :: list(HSBKA.t() | nil)
  defp fill_colors(list_hsbks, index) do
    replicate(nil, index) ++ list_hsbks
  end

  @spec get_colors_from_command(integer, map(), integer()) ::
          {:ok, list(HSBKA.t() | nil)} | {:error, String.t()}
  def get_colors_from_command(number, frame, frame_n) do
    cond do
      not is_nil(frame.colors) and number > 0 ->
        colors_index =
          case frame.colors_index do
            nil -> 0
            index -> index
          end

        case expand_colors(frame.colors, frame_n) do
          {:ok, colors} ->
            colors = fill_colors(colors, colors_index)
            {:ok, colors}

          {:error, error} ->
            {:error, "Got error in lifx expand_colors: #{error}"}
        end

      not is_nil(frame.color) ->
        values = %{"frame" => frame_n}

        case eval_color(frame.color, values) do
          {:ok, color} ->
            colors = replicate(color, number)
            {:ok, colors}

          {:error, error} ->
            {:error, "Got error in lifx eval_color: #{error}"}
        end

      true ->
        {:error, "No assigned color in get_colors_from_command"}
    end
  end
end
