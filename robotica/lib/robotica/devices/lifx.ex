defmodule Robotica.Devices.Lifx do
  @moduledoc """
  Provides LIFX support functions.
  """

  alias RoboticaPlugins.String

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
  ...> }, values)
  {:ok, %Lifx.Protocol.HSBK{
    brightness: 100,
    hue: 2,
    saturation: 4,
    kelvin: 3500,
  }}
  """
  def eval_color(color, values) do
    with {:ok, brightness} <- String.eval_string(color.brightness, values),
         {:ok, hue} <- String.eval_string(color.hue, values),
         {:ok, saturation} <- String.eval_string(color.saturation, values),
         {:ok, kelvin} <- String.eval_string(color.kelvin, values) do
      color = %Lifx.Protocol.HSBK{
        brightness: brightness,
        hue: hue,
        saturation: saturation,
        kelvin: kelvin
      }

      {:ok, color}
    else
      {:error, error} -> {:error, error}
    end
  end

  @doc """
  Expand and eval a condensed list of colors.

  iex> import Robotica.Devices.Lifx
  iex> alias Lifx.Protocol.HSBK
  iex> color = %{
  ...>   brightness: 100,
  ...>   hue: "{frame}*30",
  ...>   saturation: "{light}*100",
  ...>   kelvin: 3500,
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
    %HSBK{brightness: 100, hue: 30, saturation: 0, kelvin: 3500},
    %HSBK{brightness: 100, hue: 30, saturation: 0, kelvin: 3500},
  ]}
  iex> expand_colors(colors, 2)
  {:ok, [
  %HSBK{brightness: 100, hue: 60, saturation: 0, kelvin: 3500},
  %HSBK{brightness: 100, hue: 60, saturation: 0, kelvin: 3500},
  %HSBK{brightness: 100, hue: 60, saturation: 100, kelvin: 3500},
  %HSBK{brightness: 100, hue: 60, saturation: 100, kelvin: 3500},
  ]}
  iex> expand_colors(colors, 3)
  {:ok, [
  %HSBK{brightness: 100, hue: 90, saturation: 0, kelvin: 3500},
  %HSBK{brightness: 100, hue: 90, saturation: 0, kelvin: 3500},
  %HSBK{brightness: 100, hue: 90, saturation: 100, kelvin: 3500},
  %HSBK{brightness: 100, hue: 90, saturation: 100, kelvin: 3500},
  %HSBK{brightness: 100, hue: 90, saturation: 200, kelvin: 3500},
  %HSBK{brightness: 100, hue: 90, saturation: 200, kelvin: 3500},
  ]}
  """
  def expand_colors(list, frame_n), do: loop_colors(list, frame_n, [])

  defp loop_colors([], _, result), do: {:ok, Enum.reverse(result)}

  defp loop_colors([head | tail], frame_n, result) do
    values = %{
      "frame" => frame_n
    }

    with {:ok, count} <- String.eval_string(head.count, values),
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
end
