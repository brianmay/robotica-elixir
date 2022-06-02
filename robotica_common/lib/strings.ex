defmodule RoboticaCommon.Strings do
  @moduledoc """
  Provides String parsing and evaluation functions.
  """

  @doc """
  Substitute {xyz} values from a dictionary in a string.

  iex> import RoboticaCommon.Strings
  iex> replace_values("{i}-{j}", %{"i" => "hello", "j" => "world"})
  {:ok, "hello-world"}

  iex> import RoboticaCommon.Strings
  iex> replace_values("!{i}-{j}$", %{"i" => "hello", "j" => "world"})
  {:ok, "!hello-world$"}

  iex> import RoboticaCommon.Strings
  iex> replace_values("!{i-{j}$", %{"i" => "hello", "j" => "world"})
  {:error, "Missing closing bracket on 'i-'."}

  iex> import RoboticaCommon.Strings
  iex> replace_values("!{i}-}-{j}$", %{"i" => "hello", "j" => "world"})
  {:ok, "!hello-}-world$"}

  iex> import RoboticaCommon.Strings
  iex> replace_values("goodbye", %{"i" => "hello", "j" => "world"})
  {:ok, "goodbye"}

  iex> import RoboticaCommon.Strings
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
            map = Enum.map_join(values, ", ", fn {a, b} -> "#{a}=#{b}" end)

            {:error, "Cannot find #{name} in lookup table of #{map}."}
        end
    end
  end

  @doc """
  Substitute values in string and solve simple maths.

  iex> import RoboticaCommon.Strings
  iex> eval_string(10, %{"i" => 10, "j" => 20})
  {:ok, 10}

  iex> import RoboticaCommon.Strings
  iex> eval_string("{i}+{j}", %{"i" => 10, "j" => 20})
  {:ok, 30}

  iex> import RoboticaCommon.Strings
  iex> eval_string("{x}+{y}", %{"i" => 10, "j" => 20})
  {:error, "Cannot find x in lookup table of i=10, j=20."}
  """

  @spec eval_string(String.t() | integer(), %{required(String.t()) => integer()}) ::
          {:ok, integer()} | {:error, String.t()}
  def eval_string(string, values) do
    cond do
      is_integer(string) ->
        {:ok, string}

      is_float(string) ->
        {:ok, round(string)}

      true ->
        string = to_charlist(string)

        with {:ok, tokens, _} <- :lexer.string(string),
             {:ok, tree} <- :parser.parse(tokens) do
          {:ok, eval(tree, values)}
        else
          {:error, {line, :lexer, error}, _} ->
            {:error, "lexer error #{line}: #{inspect(error)}"}

          {:error, {line, :parser, error}} ->
            {:error, "parser error #{line}: #{inspect(error)}"}
        end
    end
  catch
    {:undefined, name} ->
      map = Enum.map_join(values, ", ", fn {a, b} -> "#{a}=#{b}" end)
      {:error, "Cannot find #{name} in lookup table of #{map}."}
  end

  # two mutally recursive data types, defining the AST
  @type expr_ast ::
          {:mult, aterm, aterm}
          | {:divi, aterm, aterm}
          | {:plus, aterm, aterm}
          | {:minus, aterm, aterm}
          | aterm

  @type aterm ::
          {:number, any(), integer()}
          | {:word, any(), String.t()}
          | expr_ast

  # and the spec for evaluator function
  @spec eval(expr_ast, store :: map) :: integer()
  # where `store` is a map of words to their values

  # evaluating a number returns its value
  defp eval({:number, _, n}, _store), do: n
  # evaluating a word returns its value from the store
  # or throws an exception
  defp eval({:word, _, word}, store) do
    case Map.fetch(store, word) do
      {:ok, val} -> val
      :error -> throw({:undefined, word})
    end
  end

  # evaluation a binary operation is an application
  # of a corresponding operator to the lhs and rhs
  # evaluated recursively
  defp eval({:mult, lhs, rhs}, s), do: eval(lhs, s) * eval(rhs, s)
  defp eval({:divi, lhs, rhs}, s), do: div(eval(lhs, s), eval(rhs, s))
  defp eval({:plus, lhs, rhs}, s), do: eval(lhs, s) + eval(rhs, s)
  defp eval({:minus, lhs, rhs}, s), do: eval(lhs, s) - eval(rhs, s)
end
