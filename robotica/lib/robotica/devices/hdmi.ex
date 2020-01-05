defmodule Robotica.Devices.HDMI do
  @moduledoc "Control HDMI switch"

  defp calc_checksum(cmd) do
    num = Enum.reduce(cmd, fn v, acc -> v + acc end)

    case rem(num, 0x100) do
      0 -> 0
      x -> 0x100 - x
    end
  end

  defp cmd_to_url(host, cmd) do
    cmd = cmd ++ [calc_checksum(cmd)]
    cmd = Enum.map(cmd, fn v -> v |> Integer.to_string(16) |> String.pad_leading(2, "0") end)
    "http://#{host}/cgi-bin/submit?cmd=hex(" <> Enum.join(cmd, ",") <> ")"
  end

  def switch(host, input, output) do
    cmd = [0xa5, 0x5b, 0x02, 0x03, input, 0x00, output, 0x00, 0x00, 0x00, 0x00, 0x00]
    url = cmd_to_url(host, cmd)
    case Mojito.request(:get, url) do
      {:ok, %{status_code: 200}} -> :ok
      {:ok, %{status_code: code}} -> {:error, "Got HTTP response #{code}"}
      {:error, msg} -> {:error, msg}
    end
  end
end
