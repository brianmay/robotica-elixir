defmodule Robotica.Devices.HDMI do
  @moduledoc "Control HDMI switch"

  @spec calc_checksum(list(integer)) :: integer()
  defp calc_checksum(cmd) do
    num = Enum.reduce(cmd, fn v, acc -> v + acc end)

    case rem(num, 0x100) do
      0 -> 0
      x -> 0x100 - x
    end
  end

  @spec add_checksum(list(integer)) :: list(integer)
  defp add_checksum(cmd) do
    cmd ++ [calc_checksum(cmd)]
  end

  @spec check_checksum(list(integer)) :: :ok | {:error, String.t()}
  defp check_checksum(cmd) do
    checksum = List.last(cmd)

    calculated =
      cmd
      |> Enum.reverse()
      |> tl()
      |> Enum.reverse()
      |> calc_checksum()

    if calculated == checksum do
      :ok
    else
      {:error, "Checksum wrong."}
    end
  end

  @spec check_response(list(integer), list(integer)) :: :ok | {:error, String.t()}
  def check_response(cmd, response) do
    a = Enum.take(cmd, 5)
    b = Enum.take(response, 5)

    if a == b do
      :ok
    else
      {:error, "Wrong response."}
    end
  end

  @spec cmd_to_url(String.t(), list(integer)) :: String.t()
  defp cmd_to_url(host, cmd) do
    cmd = Enum.map(cmd, fn v -> v |> Integer.to_string(16) |> String.pad_leading(2, "0") end)
    "http://#{host}/cgi-bin/submit?cmd=hex(" <> Enum.join(cmd, ",") <> ")"
  end

  @spec get_cmd_switch(integer, integer) :: list(integer())
  def get_cmd_switch(input, output) do
    [0xA5, 0x5B, 0x02, 0x03, input, 0x00, output, 0x00, 0x00, 0x00, 0x00, 0x00]
    |> add_checksum()
  end

  @spec get_cmd_input_for_output(integer) :: list(integer())
  def get_cmd_input_for_output(output) do
    [0xA5, 0x5B, 0x02, 0x01, output, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]
    |> add_checksum()
  end

  @spec send_command(String.t(), list(integer())) :: :ok | {:error, String.t()}
  def send_command(host, cmd) do
    url = cmd_to_url(host, cmd)

    case Mojito.request(:get, url) do
      {:ok, %{status_code: 200}} -> :ok
      {:ok, %{status_code: code}} -> {:error, "Got HTTP response #{code}"}
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

  @spec parse_values_array(list(String.t()), list(integer())) ::
          {:ok, list(integer())} | {:error, String.t()}
  defp parse_values_array([], result), do: {:ok, Enum.reverse(result)}

  defp parse_values_array([head | tail], result) do
    case Integer.parse(head, 16) do
      {value, ""} -> parse_values_array(tail, [value | result])
      _ -> {:error, "Unable to parse hex value #{head}"}
    end
  end

  @spec parse_values(String.t()) :: {:ok, list(integer())} | {:error, String.t()}
  defp parse_values(string) do
    string
    |> String.split(",")
    |> parse_values_array([])
  end

  @spec parse_postfix(String.t()) :: {:ok, list(integer())} | {:error, String.t()}
  defp parse_postfix(string) do
    case String.split(string, ")", parts: 2) do
      [values, ""] -> parse_values(values)
      _ -> {:error, "Illegal postfix #{inspect(string)}"}
    end
  end

  @spec parse_result(String.t()) :: {:ok, list(integer())} | {:error, String.t()}
  defp parse_result(string) do
    case String.split(string, "(", parts: 2) do
      ["hex", tail] -> parse_postfix(tail)
      _ -> {:error, "Illegal response #{inspect(string)}"}
    end
  end

  @spec switch(String.t(), integer, integer) :: :ok | {:error, String.t()}
  def switch(host, input, output) do
    cmd = get_cmd_switch(input, output)

    case send_command(host, cmd) do
      :ok -> :ok
      {:error, error} -> {:error, error}
    end
  end

  @spec get_input_for_output(String.t(), integer) :: {:ok, integer} | {:error, String.t()}
  def get_input_for_output(host, output) do
    cmd = get_cmd_input_for_output(output)

    with :ok <- send_command(host, cmd),
         Process.sleep(50),
         {:ok, body} <- get_result(host),
         {:ok, response} <- parse_result(body),
         :ok <- check_checksum(response),
         :ok <- check_response(cmd, response) do
      {:ok, Enum.at(response, 6)}
    else
      {:error, msg} -> {:error, msg}
    end
  end
end
