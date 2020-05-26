defmodule RoboticaPlugins.String do
  @moduledoc """
  Provides String parsing and evaluation functions.
  """

  @doc """
  Substitute {xyz} values from a dictionary in a string.

  iex> import RoboticaPlugins.String
  iex> replace_values("{i}-{j}", %{"i" => "hello", "j" => "world"})
  {:ok, "hello-world"}

  iex> import RoboticaPlugins.String
  iex> replace_values("!{i}-{j}$", %{"i" => "hello", "j" => "world"})
  {:ok, "!hello-world$"}

  iex> import RoboticaPlugins.String
  iex> replace_values("!{i-{j}$", %{"i" => "hello", "j" => "world"})
  {:error, "Missing closing bracket on 'i-'."}

  iex> import RoboticaPlugins.String
  iex> replace_values("!{i}-}-{j}$", %{"i" => "hello", "j" => "world"})
  {:ok, "!hello-}-world$"}

  iex> import RoboticaPlugins.String
  iex> replace_values("goodbye", %{"i" => "hello", "j" => "world"})
  {:ok, "goodbye"}

  iex> import RoboticaPlugins.String
  iex> replace_values("{x}-{y}", %{"i" => "hello", "j" => "world"})
  {:error, "Cannot find x in lookup table of i=hello, j=world."}
  """
  @spec replace_values(String.t(), %{required(String.t()) => String.t()}) ::
          {:ok, String.t()} | {:error, String.t()}
  def replace_values(string, values) do
    case String.split(string, "{") do
      [value] -> {:ok, value}
      [str | list] -> replace_values_internal(list, values, [str])
    end
  end

  defp replace_values_internal([], _values, result) do
    result =
      result
      |> Enum.reverse()
      |> Enum.join("")

    {:ok, result}
  end

  defp replace_values_internal([str | rest], values, result) do
    case String.split(str, "}", parts: 2) do
      [value] ->
        {:error, "Missing closing bracket on '#{value}'."}

      [name, str] ->
        case Map.fetch(values, name) do
          {:ok, value} ->
            result = [value | result]
            result = [str | result]
            replace_values_internal(rest, values, result)

          :error ->
            map =
              values
              |> Enum.map(fn {a, b} -> "#{a}=#{b}" end)
              |> Enum.join(", ")

            {:error, "Cannot find #{name} in lookup table of #{map}."}
        end
    end
  end

  @doc """
  Solve (simple) maths in a string.

  iex> import RoboticaPlugins.String
  iex> solve_string("1")
  {:ok, 1}

  iex> import RoboticaPlugins.String
  iex> solve_string("1+2")
  {:ok, 3}

  iex> import RoboticaPlugins.String
  iex> solve_string("1+-2")
  {:ok, -1}

  iex> import RoboticaPlugins.String
  iex> solve_string("-1+2")
  {:ok, 1}

  iex> import RoboticaPlugins.String
  iex> solve_string("2*3")
  {:ok, 6}

  iex> import RoboticaPlugins.String
  iex> solve_string("2*1.5")
  {:ok, 3}

  iex> import RoboticaPlugins.String
  iex> solve_string("1+2*3")
  {:ok, 7}
  iex> solve_string("2*3+1")
  {:ok, 7}

  iex> import RoboticaPlugins.String
  iex> solve_string("2*3+1*2*1")
  {:ok, 8}

  iex> import RoboticaPlugins.String
  iex> solve_string("1+")
  {:error, "Cannot parse '' as float."}

  iex> import RoboticaPlugins.String
  iex> solve_string("1*")
  {:error, "Cannot parse '' as float."}

  iex> import RoboticaPlugins.String
  iex> solve_string("n")
  {:error, "Cannot parse 'n' as float."}

  iex> import RoboticaPlugins.String
  iex> solve_string("10n")
  {:error, "Cannot parse '10n' as float."}
  """
  @spec solve_string(String.t()) :: {:ok, integer()} | {:error, String.t()}
  def solve_string(string) do
    sum_parts = String.split(string, "+")
    solve_sums(sum_parts, 0)
  end

  defp solve_sums([], result) when is_integer(result), do: {:ok, result}
  defp solve_sums([], result) when is_float(result), do: {:ok, Float.round(result) |> trunc}

  defp solve_sums([head | tail], result) do
    this_result =
      head
      |> String.split("*")
      |> solve_multiplications(1)

    case this_result do
      {:ok, value} -> solve_sums(tail, result + value)
      {:error, error} -> {:error, error}
    end
  end

  defp parse_float(value) do
    case Float.parse(value) do
      {value, ""} ->
        {:ok, value}

      {_, _} ->
        {:error, "Cannot parse '#{value}' as float."}

      :error ->
        {:error, "Cannot parse '#{value}' as float."}
    end
  end

  defp parse_integer(value) do
    case Integer.parse(value) do
      {value, ""} ->
        {:ok, value}

      {_, _} ->
        {:error, "Cannot parse '#{value}' as integer."}

      :error ->
        {:error, "Cannot parse '#{value}' as integer."}
    end
  end

  defp parse_integer_or_float(value) do
    case parse_integer(value) do
      {:ok, value} -> {:ok, value}
      {:error, _} -> parse_float(value)
    end
  end

  defp solve_multiplications([], result), do: {:ok, result}

  defp solve_multiplications([head | tail], result) do
    case parse_integer_or_float(head) do
      {:ok, value} ->
        solve_multiplications(tail, result * value)

      {:error, error} ->
        {:error, error}
    end
  end

  @doc """
  Substitute values in string and solve simple maths.

  iex> import RoboticaPlugins.String
  iex> eval_string(10, %{"i" => "10", "j" => "20"})
  {:ok, 10}

  iex> import RoboticaPlugins.String
  iex> eval_string("{i}+{j}", %{"i" => "10", "j" => "20"})
  {:ok, 30}

  iex> import RoboticaPlugins.String
  iex> eval_string("{x}+{y}", %{"i" => "10", "j" => "20"})
  {:error, "Cannot find x in lookup table of i=10, j=20."}

  iex> import RoboticaPlugins.String
  iex> eval_string("{i}+{j}", %{"i" => "10a", "j" => "20b"})
  {:error, "Cannot parse '10a' as float."}
  """

  @spec eval_string(String.t() | integer(), %{required(String.t()) => String.t()}) ::
          {:ok, integer()} | {:error, String.t()}
  def eval_string(string, values) do
    cond do
      is_integer(string) ->
        {:ok, string}

      true ->
        with {:ok, string} <- replace_values(string, values),
             {:ok, result} <- solve_string(string) do
          {:ok, result}
        else
          {:error, error} -> {:error, error}
        end
    end
  end

  @doc """
  Substitute values in string. Solve simple maths if prefixed with =.

  iex> import RoboticaPlugins.String
  iex> solve_string("{i}+{j}", %{"i" => "10", "j" => "20"})
  {:ok, "10+20"}

  iex> import RoboticaPlugins.String
  iex> solve_string("={i}+{j}", %{"i" => "10", "j" => "20"})
  {:ok, "30"}

  iex> import RoboticaPlugins.String
  iex> solve_string("={x}+{y}", %{"i" => "10", "j" => "20"})
  {:error, "Cannot find x in lookup table of i=10, j=20."}

  iex> import RoboticaPlugins.String
  iex> solve_string("={i}+{j}", %{"i" => "10a", "j" => "20"})
  {:error, "Cannot parse '10a' as float."}
  """
  @spec solve_string(String.t(), %{required(String.t()) => String.t()}) ::
          {:ok, String.t()} | {:error, String.t()}
  def solve_string(string, values) do
    case replace_values(string, values) do
      {:ok, "=" <> remain} ->
        case solve_string(remain) do
          {:ok, result} -> {:ok, Integer.to_string(result)}
          {:error, error} -> {:error, error}
        end

      {:ok, string} ->
        {:ok, string}

      {:error, error} ->
        {:error, error}
    end
  end

  defp solve_string_combined_list([], _, result) do
    {:ok, result |> Enum.reverse() |> Enum.join("")}
  end

  defp solve_string_combined_list([head | tail], values, result) do
    case solve_string(head, values) do
      {:ok, value} -> solve_string_combined_list(tail, values, [value | result])
      {:error, error} -> {:error, error}
    end
  end

  @doc """
  Substitute values in string with ++ to separate items.

  iex> import RoboticaPlugins.String
  iex> solve_string_combined("{i}+{j}++1+2", %{"i" => "10", "j" => "20"})
  {:ok, "10+201+2"}

  iex> import RoboticaPlugins.String
  iex> solve_string_combined("={i}+{j}++1+2", %{"i" => "10", "j" => "20"})
  {:ok, "301+2"}

  iex> import RoboticaPlugins.String
  iex> solve_string_combined("={x}+{y}++1+2", %{"i" => "10", "j" => "20"})
  {:error, "Cannot find x in lookup table of i=10, j=20."}

  iex> import RoboticaPlugins.String
  iex> solve_string_combined("={i}+{j}++1+2", %{"i" => "10a", "j" => "20"})
  {:error, "Cannot parse '10a' as float."}
  """
  @spec solve_string_combined(String.t(), %{required(String.t()) => String.t()}) ::
          {:ok, String.t()} | {:error, String.t()}
  def solve_string_combined(string, values) do
    String.split(string, "++")
    |> solve_string_combined_list(values, [])
  end
end
