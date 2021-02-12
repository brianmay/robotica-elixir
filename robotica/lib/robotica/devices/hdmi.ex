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

  @spec switch(String.t(), integer, integer) :: :ok | {:error, String.t()}
  def switch(host, input, output) do
    cmd = [0xA5, 0x5B, 0x02, 0x03, input, 0x00, output, 0x00, 0x00, 0x00, 0x00, 0x00]
    url = cmd_to_url(host, cmd)

    case Mojito.request(:get, url) do
      {:ok, %{status_code: 200}} -> :ok
      {:ok, %{status_code: code}} -> {:error, "Got HTTP response #{code}"}
      {:error, msg} -> {:error, "Got hdmi error #{inspect(msg)}"}
    end
  end

  @spec cmd_get_input_for_output(String.t(), integer) :: :ok | {:error, String.t()}
  def cmd_get_input_for_output(host, output) do
    cmd = [0xA5, 0x5B, 0x02, 0x01, output, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]
    url = cmd_to_url(host, cmd)

    case Mojito.request(:get, url) do
      {:ok, %{status_code: 200}} -> :ok
      {:ok, %{status_code: code}} -> {:error, "1Got HTTP response #{code}"}
      {:error, msg} -> {:error, "Got hdmi error #{inspect(msg)}"}
    end
  end

  @spec get_result(String.t()) :: {:ok, String.t()} | {:error, String.t()}
  def get_result(host) do
    url = "http://#{host}/cgi-bin/query"

    case Mojito.request(:get, url) do
      {:ok, %{status_code: 200, body: body}} -> {:ok, body}
      {:ok, %{status_code: code}} -> {:error, "2Got HTTP response #{code}"}
      {:error, msg} -> {:error, "Got hdmi error #{inspect(msg)}"}
    end
  end

  @spec get_input_for_output(String.t(), integer) :: {:ok, integer} | {:error, String.t()}
  def get_input_for_output(host, output) do
    with :ok <- cmd_get_input_for_output(host, output),
         {:ok, body} <- get_result(host) do
      IO.inspect(body)
      {:ok, 99}
    else
      {:error, msg} -> {:error, msg}
    end
  end
end
