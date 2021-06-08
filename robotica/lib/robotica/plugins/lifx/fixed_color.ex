defmodule Robotica.Plugins.Lifx.FixedColor do
  @moduledoc """
  LIFX Animation that displays a fixed color
  """

  alias Robotica.Devices.Lifx, as: RLifx
  alias Robotica.Devices.Lifx.HSBKA

  @spec go(RLifx.callback(), integer(), list(HSBKA.t())) :: :ok
  def go(sender, power, colors) do
    sender.(power, colors)
    Process.sleep(60_000)
    go(sender, power, colors)
  end
end
