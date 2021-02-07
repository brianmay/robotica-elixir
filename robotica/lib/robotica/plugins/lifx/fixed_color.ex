defmodule Robotica.Plugins.Lifx.FixedColor do
  alias Robotica.Devices.Lifx, as: RLifx
  alias Robotica.Devices.Lifx.HSBKA

  @spec loop() :: :ok
  def loop() do
    Process.sleep(3_600_000)
    loop()
  end

  @spec go(RLifx.callback(), integer(), list(HSBKA.t())) :: :ok
  def go(sender, power, colors) do
    sender.(power, colors)
    loop()
  end
end
