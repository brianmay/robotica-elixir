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
  iex> eval_string_to_integer(10, %{"i" => 10, "j" => 20})
  {:ok, 10}

  iex> import RoboticaCommon.Strings
  iex> eval_string_to_integer("i+j", %{"i" => 10, "j" => 20})
  {:ok, 30}

  iex> import RoboticaCommon.Strings
  iex> eval_string_to_integer("x+y", %{"i" => 10, "j" => 20})
  {:error, "Cannot find x in lookup table of i=10, j=20."}

  iex> import RoboticaCommon.Strings
  iex> eval_string_to_integer("i%2", %{"i" => 10, "j" => 20})
  {:ok, 0}

  iex> import RoboticaCommon.Strings
  iex> eval_string_to_integer("i%2", %{"i" => 11, "j" => 20})
  {:ok, 1}

  iex> import RoboticaCommon.Strings
  iex> {:error, _} = eval_string_to_integer("1==2 or 2==3", %{"i" => 11, "j" => 20})
  """

  @spec eval_string_to_integer(String.t() | integer(), %{required(String.t()) => integer()}) ::
          {:ok, integer()} | {:error, String.t()}
  def eval_string_to_integer(string, values) do
    cond do
      is_integer(string) ->
        {:ok, string}

      is_float(string) ->
        {:ok, round(string)}

      true ->
        string = to_charlist(string)

        with {:ok, tokens, _} <- :lexer.string(string),
             {:ok, tree} <- :parser.parse(tokens) do
          {:ok, eval_int(tree, values)}
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

    {:illegal_lookup_type, value, expected_type} ->
      {:error, "Illegal value #{inspect(value)}, expected type #{expected_type}."}

    {:illegal_term, term} ->
      {:error, "Illegal term #{inspect(term)}."}
  end

  @doc """
  Substitute values in string and solve simple maths.

  iex> import RoboticaCommon.Strings
  iex> eval_string_to_bool("10==10", %{})
  {:ok, true}

  iex> import RoboticaCommon.Strings
  iex> eval_string_to_bool("10==11", %{})
  {:ok, false}

  iex> import RoboticaCommon.Strings
  iex> eval_string_to_bool("11>11", %{})
  {:ok, false}

  iex> import RoboticaCommon.Strings
  iex> eval_string_to_bool("12>11", %{})
  {:ok, true}

  iex> import RoboticaCommon.Strings
  iex> eval_string_to_bool("10>=11", %{})
  {:ok, false}

  iex> import RoboticaCommon.Strings
  iex> eval_string_to_bool("11>=11", %{})
  {:ok, true}

  iex> import RoboticaCommon.Strings
  iex> eval_string_to_bool("11<11", %{})
  {:ok, false}

  iex> import RoboticaCommon.Strings
  iex> eval_string_to_bool("10<11", %{})
  {:ok, true}

  iex> import RoboticaCommon.Strings
  iex> eval_string_to_bool("12<=11", %{})
  {:ok, false}

  iex> import RoboticaCommon.Strings
  iex> eval_string_to_bool("11<=11", %{})
  {:ok, true}

  iex> import RoboticaCommon.Strings
  iex> eval_string_to_bool("10==10 or 11==10", %{})
  {:ok, true}

  iex> import RoboticaCommon.Strings
  iex> eval_string_to_bool("10==9 or 11==10", %{})
  {:ok, false}

  iex> import RoboticaCommon.Strings
  iex> eval_string_to_bool("10==10 or 11==10 or 12==10", %{})
  {:ok, true}

  iex> import RoboticaCommon.Strings
  iex> eval_string_to_bool("10==10 and 11==11", %{})
  {:ok, true}

  iex> import RoboticaCommon.Strings
  iex> eval_string_to_bool("10==10 and 11==10", %{})
  {:ok, false}

  iex> import RoboticaCommon.Strings
  iex> eval_string_to_bool("(10==10 or 11==10) and 12==10", %{})
  {:ok, false}

  iex> import RoboticaCommon.Strings
  iex> eval_string_to_bool("10==10 or (11==10 or 12==10)", %{})
  {:ok, true}

  iex> import RoboticaCommon.Strings
  iex> eval_string_to_bool("10==10 or 11==10 and 12==10", %{})
  {:ok, false}

  iex> import RoboticaCommon.Strings
  iex> eval_string_to_bool("not 10==10", %{})
  {:ok, false}

  iex> import RoboticaCommon.Strings
  iex> eval_string_to_bool("not (10==10 or 11==11)", %{})
  {:ok, false}

  iex> import RoboticaCommon.Strings
  iex> eval_string_to_bool("(not 10==10) or 11==11", %{})
  {:ok, true}

  iex> import RoboticaCommon.Strings
  iex> eval_string_to_bool("not 10==10 or 11==11", %{})
  {:ok, true}

  iex> import RoboticaCommon.Strings
  iex> eval_string_to_bool("'abc'=='abc'", %{})
  {:ok, true}

  iex> import RoboticaCommon.Strings
  iex> eval_string_to_bool("'abc'!='abc'", %{})
  {:ok, false}

  iex> import RoboticaCommon.Strings
  iex> eval_string_to_bool("'abc'=='def'", %{})
  {:ok, false}

  iex> import RoboticaCommon.Strings
  iex> eval_string_to_bool("'abc'!='def'", %{})
  {:ok, true}

  iex> import RoboticaCommon.Strings
  iex> eval_string_to_bool("'abc'==value", %{"value" => "abc"})
  {:ok, true}

  iex> import RoboticaCommon.Strings
  iex> eval_string_to_bool("'abc'!=value", %{"value" => "abc"})
  {:ok, false}

  iex> import RoboticaCommon.Strings
  iex> eval_string_to_bool("'abc'==value", %{"value" => "def"})
  {:ok, false}

  iex> import RoboticaCommon.Strings
  iex> eval_string_to_bool("'abc'!=value", %{"value" => "def"})
  {:ok, true}

  iex> import RoboticaCommon.Strings
  iex> eval_string_to_bool("'abc' in type", %{"type" => MapSet.new(["abc"])})
  {:ok, true}

  iex> import RoboticaCommon.Strings
  iex> eval_string_to_bool("'abc' not in type", %{"type" => MapSet.new(["abc"])})
  {:ok, false}

  iex> import RoboticaCommon.Strings
  iex> eval_string_to_bool("'def' in type", %{"type" => MapSet.new(["abc"])})
  {:ok, false}

  iex> import RoboticaCommon.Strings
  iex> eval_string_to_bool("'def' not in type", %{"type" => MapSet.new(["abc"])})
  {:ok, true}
  """

  @spec eval_string_to_bool(String.t() | integer(), %{required(String.t()) => integer()}) ::
          {:ok, boolean()} | {:error, String.t()}
  def eval_string_to_bool(string, values) do
    cond do
      is_integer(string) ->
        {:ok, string}

      is_float(string) ->
        {:ok, round(string)}

      true ->
        string = to_charlist(string)

        with {:ok, tokens, _} <- :lexer.string(string),
             {:ok, tree} <- :cond_parser.parse(tokens) do
          {:ok, eval_cond(tree, values)}
        else
          {:error, {line, :lexer, error}, _} ->
            {:error, "lexer error #{line}: #{inspect(error)}"}

          {:error, {line, :cond_parser, error}} ->
            {:error, "parser error #{line}: #{inspect(error)}"}
        end
    end
  catch
    {:undefined, name} ->
      map = Enum.map_join(values, ", ", fn {a, b} -> "#{a}=#{inspect(b)}" end)
      {:error, "Cannot find #{name} in lookup table of #{map}."}

    {:illegal_lookup_type, value, expected_type} ->
      {:error, "Illegal value #{inspect(value)}, expected type #{expected_type}."}

    {:illegal_term, term} ->
      {:error, "Illegal term #{inspect(term)}."}
  end

  # two mutally recursive data types, defining the AST
  @type expr_ast ::
          {:multiple, aterm, aterm}
          | {:divide, aterm, aterm}
          | {:remainder, aterm, aterm}
          | {:plus, aterm, aterm}
          | {:minus, aterm, aterm}
          | aterm

  @type aterm ::
          {:number, any(), integer()}
          | {:word, any(), String.t()}
          | {:string, any(), String.t()}
          | expr_ast

  # and the spec for evaluator function
  # where `store` is a map of words to their values
  @spec eval_int(expr_ast, store :: map) :: integer()
  # evaluating a number returns its value
  defp eval_int({:number, _, n}, _store), do: n
  # evaluating a string returns its value
  defp eval_int({:string, _, _} = term, _store), do: throw({:illegal_lookup_type, term})
  # evaluating a word returns its value from the store
  # or throws an exception
  defp eval_int({:word, _, word}, store) do
    case Map.fetch(store, word) do
      {:ok, val} when not is_integer(val) -> throw({:illegal_lookup_type, val, "integer"})
      {:ok, val} -> val
      :error -> throw({:undefined, word})
    end
  end

  # evaluation a binary operation is an application
  # of a corresponding operator to the lhs and rhs
  # evaluated recursively
  defp eval_int({:multiply, lhs, rhs}, s), do: eval_int(lhs, s) * eval_int(rhs, s)
  defp eval_int({:divide, lhs, rhs}, s), do: div(eval_int(lhs, s), eval_int(rhs, s))
  defp eval_int({:remainder, lhs, rhs}, s), do: rem(eval_int(lhs, s), eval_int(rhs, s))
  defp eval_int({:plus, lhs, rhs}, s), do: eval_int(lhs, s) + eval_int(rhs, s)
  defp eval_int({:minus, lhs, rhs}, s), do: eval_int(lhs, s) - eval_int(rhs, s)

  # and the spec for evaluator function
  # where `store` is a map of words to their values
  @spec eval_str(expr_ast, store :: map) :: String.t()
  # evaluating a string returns its value
  defp eval_str({:string, _, str}, _store), do: str
  # evaluating a word returns its value from the store
  # or throws an exception
  defp eval_str({:word, _, word}, store) do
    case Map.fetch(store, word) do
      {:ok, val} when not is_binary(val) -> throw({:illegal_lookup_type, val, "string"})
      {:ok, val} -> val
      :error -> throw({:undefined, word})
    end
  end

  # integer operations not valid for strings
  defp eval_str({:number, _, _} = term, _store), do: throw({:illegal_term, term})
  defp eval_str({:multiply, _, _} = term, _), do: throw({:illegal_term, term})
  defp eval_str({:divide, _, _} = term, _), do: throw({:illegal_term, term})
  defp eval_str({:remainder, _, _} = term, _), do: throw({:illegal_term, term})
  defp eval_str({:plus, _, _} = term, _), do: throw({:illegal_term, term})
  defp eval_str({:minus, _, _} = term, _), do: throw({:illegal_term, term})

  # and the spec for evaluator function
  # where `store` is a map of words to their values
  @spec eval_mapset(expr_ast, store :: map) :: MapSet.t()
  defp eval_mapset({:word, _, word}, store) do
    case Map.fetch(store, word) do
      # dialzyer does not like this
      # {:ok, %MapSet{} = val} -> val
      # {:ok, val} -> throw({:illegal_lookup_type, val, "mapset"})

      {:ok, val} ->
        val

      :error ->
        throw({:undefined, word})
    end
  end

  defp eval_mapset(term, _), do: throw({:illegal_term, term})

  defp eval_cond({:not, rhs}, s), do: not eval_cond(rhs, s)
  defp eval_cond({:and, lhs, rhs}, s), do: eval_cond(lhs, s) and eval_cond(rhs, s)
  defp eval_cond({:in, lhs, rhs}, s), do: MapSet.member?(eval_mapset(rhs, s), eval_str(lhs, s))

  defp eval_cond({:not_in, lhs, rhs}, s),
    do: not MapSet.member?(eval_mapset(rhs, s), eval_str(lhs, s))

  defp eval_cond({:or, lhs, rhs}, s), do: eval_cond(lhs, s) or eval_cond(rhs, s)

  defp eval_cond({:eq, {:string, _, _} = lhs, rhs}, s), do: eval_str(lhs, s) == eval_str(rhs, s)
  defp eval_cond({:ne, {:string, _, _} = lhs, rhs}, s), do: eval_str(lhs, s) != eval_str(rhs, s)
  defp eval_cond({:eq, lhs, {:string, _, _} = rhs}, s), do: eval_str(lhs, s) == eval_str(rhs, s)
  defp eval_cond({:ne, lhs, {:string, _, _} = rhs}, s), do: eval_str(lhs, s) != eval_str(rhs, s)

  defp eval_cond({:eq, lhs, rhs}, s), do: eval_int(lhs, s) == eval_int(rhs, s)
  defp eval_cond({:ne, lhs, rhs}, s), do: eval_int(lhs, s) != eval_int(rhs, s)
  defp eval_cond({:lt, lhs, rhs}, s), do: eval_int(lhs, s) < eval_int(rhs, s)
  defp eval_cond({:le, lhs, rhs}, s), do: eval_int(lhs, s) <= eval_int(rhs, s)
  defp eval_cond({:gt, lhs, rhs}, s), do: eval_int(lhs, s) > eval_int(rhs, s)
  defp eval_cond({:ge, lhs, rhs}, s), do: eval_int(lhs, s) >= eval_int(rhs, s)
end
