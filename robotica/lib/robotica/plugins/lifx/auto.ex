defmodule Robotica.Plugins.Lifx.Auto do
  @moduledoc """
  LIFX Animation that displays a fixed color
  """

  alias Robotica.Devices.Lifx, as: RLifx
  alias Robotica.Devices.Lifx.HSBKA

  @spec replicate(any(), integer()) :: list(any())
  defp replicate(x, n), do: for(i <- 0..n, i > 0, do: x)

  @spec go(RLifx.callback(), integer()) :: :ok
  def go(sender, number) do
    timezone = RoboticaCommon.Date.get_timezone()
    now = DateTime.now!(timezone)

    color =
      case now.hour do
        h when h > 21 or h < 6 ->
          %HSBKA{hue: 0, saturation: 0, brightness: 15, kelvin: 2000}

        h when h > 20 or h < 7 ->
          %HSBKA{hue: 0, saturation: 0, brightness: 50, kelvin: 2500}

        h when h > 19 or h < 9 ->
          %HSBKA{hue: 0, saturation: 0, brightness: 100, kelvin: 3000}

        _ ->
          %HSBKA{hue: 0, saturation: 0, brightness: 100, kelvin: 3500}
      end

    colors = replicate(color, number)
    power = 65_535
    sender.(power, colors)
    Process.sleep(60_000)
    go(sender, number)
  end
end
