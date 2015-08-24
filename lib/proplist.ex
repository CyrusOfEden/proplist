defmodule Proplist do
  @moduledoc """
  A proplist is a list of tuples where the first element
  of the tuple is a binary and the second element can be
  any value.

  A proplist may have duplicated props so it is not strictly
  a dictionary. However most of the functions in this module
  behave exactly as a dictionary and mimic the API defined
  by the `Dict` behaviour.

  For example, `Proplist.get/3` will get the first entry matching
  the given prop, regardless if duplicated entries exist.
  Similarly, `Proplist.put/3` and `Proplist.delete/3` ensure all
  duplicated entries for a given prop are removed when invoked.

  A handful of functions exist to handle duplicated props, in
  particular, `Enum.into/2` allows creating new proplist without
  removing duplicated props, `get_values/2` returns all values for
  a given prop and `delete_first/2` deletes just one of the existing
  entries.

  Since a proplist list is simply a list, all the operations defined
  in `Enum` and `List` can be applied.
  """

  @behaviour Dict
  @type prop :: binary
  @type value :: any

  @type t :: [{prop, value}]
  @type t(value) :: [{prop, value}]

  @doc """
  Checks if the given argument is a proplist list or not.
  """
  @spec proplist?(term) :: boolean
  def proplist?([{prop, _value} | rest]) when is_binary(prop) do
    proplist?(rest)
  end

  def proplist?([]), do: true
  def proplist?(_), do: false

  @doc """
  Returns an empty property list, i.e. an empty list.
  """
  @spec new :: t
  def new do
    []
  end

  @doc """
  Creates a proplist from an enumerable.

  Duplicated entries are removed, the latest one prevails.
  Unlike `Enum.into(enumerable, [])`,
  `Proplist.new(enumerable)` guarantees the props are unique.

  ## Examples

      iex> Proplist.new([{"b", 1}, {"a", 2}])
      [{"a", 2}, {"b", 1}]
  """
  @spec new(Enum.t) :: t
  def new(pairs) do
    Enum.reduce pairs, [], fn {p, v}, proplist ->
      put(proplist, p, v)
    end
  end

  @doc """
  Creates a proplist from an enumerable via the transformation function.

  Duplicated entries are removed, the latest one prevails.
  Unlike `Enum.into(enumerable, [], fun)`,
  `Proplist.new(enumerable, fun)` guarantees the props are unique.

  ## Examples

      iex> Proplist.new(["a", "b"], fn (x) -> {x, x} end) |> Enum.sort
      [{"a", "a"}, {"b", "b"}]

  """
  def new(pairs, transform) do
    Enum.reduce pairs, [], fn i, proplist ->
      {p, v} = transform.(i)
      put(proplist, p, v)
    end
  end

  @doc """
  Gets the value for a specific `prop`.

  If `prop` does not exist, return the default value (`nil` if no default value).

  If duplicated entries exist, the first one is returned.
  Use `get_values/2` to retrieve all entries.

  ## Examples

      iex> Proplist.get([{"a", 1}], "a")
      1

      iex> Proplist.get([{"a", 1}], "b")
      nil

      iex> Proplist.get([{"a", 1}], "b", 3)
      3

  """
  @spec get(t, prop) :: value
  @spec get(t, prop, value) :: value
  def get(proplist, prop, default \\ nil) when is_list(proplist) and is_binary(prop) do
    case :lists.keyfind(prop, 1, proplist) do
      {^prop, value} -> value
      false -> default
    end
  end

  @doc """
  Fetches the value for a specific `prop` and returns it in a tuple.

  If the `prop` does not exist, returns `:error`.

  ## Examples

      iex> Proplist.fetch([{"a", 1}], "a")
      {:ok, 1}

      iex> Proplist.fetch([{"a", 1}], "b")
      :error

  """
  @spec fetch(t, prop) :: {:ok, value} | :error
  def fetch(proplist, prop) when is_list(proplist) and is_binary(prop) do
    case :lists.keyfind(prop, 1, proplist) do
      {^prop, value} -> {:ok, value}
      false -> :error
    end
  end

  @doc """
  Fetches the value for specific `prop`.

  If `prop` does not exist, a `KeyError` is raised.

  ## Examples

      iex> Proplist.fetch!([{"a", 1}], "a")
      1

      iex> Proplist.fetch!([{"a", 1}], "b")
      ** (KeyError) key "b" not found in: [{"a", 1}]

  """
  @spec fetch!(t, prop) :: value | no_return
  def fetch!(proplist, prop) when is_list(proplist) and is_binary(prop) do
    case :lists.keyfind(prop, 1, proplist) do
      {^prop, value} -> value
      false -> raise KeyError, key: prop, term: proplist
    end
  end

  @doc """
  Gets all values for a specific `prop`.

  ## Examples

      iex> Proplist.get_values([{"a", 1}, {"a", 2}], "a")
      [1,2]

  """
  @spec get_values(t, prop) :: [value]
  def get_values(proplist, prop) when is_list(proplist) and is_binary(prop) do
    fun = fn
      {p, v} when p === prop -> {true, v}
      {_, _} -> false
    end

    :lists.filtermap(fun, proplist)
  end

  @doc """
  Returns all props from the proplist list.

  Duplicated props appear duplicated in the final list of props.

  ## Examples

      iex> Proplist.props([{"a", 1}, {"b", 2}])
      ["a", "b"]

      iex> Proplist.props([{"a", 1}, {"b", 2}, {"a", 3}])
      ["a", "b", "a"]

  """
  @spec props(t) :: [prop]
  def props(proplist) when is_list(proplist) do
    :lists.map(fn {p, _} -> p end, proplist)
  end

  @doc """
  Returns all values from the proplist list.

  ## Examples

      iex> Proplist.values([{"a", 1}, {"b", 2}])
      [1,2]

  """
  @spec values(t) :: [value]
  def values(proplist) when is_list(proplist) do
    :lists.map(fn {_, v} -> v end, proplist)
  end

@doc """
  Deletes the entries in the proplist list for a `prop` with `value`.

  If no `prop` with `value` exists, returns the proplist list unchanged.

  ## Examples

      iex> Proplist.delete([{"a", 1}, {"b", 2}], "a", 1)
      [{"b", 2}]

      iex> Proplist.delete([{"a", 1}, {"b", 2}, {"a", 3}], "a", 3)
      [{"a", 1}, {"b", 2}]

      iex> Proplist.delete([{"b", 2}], "a", 5)
      [{"b", 2}]

  """
  @spec delete(t, prop, value) :: t
  def delete(proplist, prop, value) when is_list(proplist) and is_binary(prop) do
    :lists.filter(fn {k, v} -> k != prop or v != value end, proplist)
  end

  @doc """
  Deletes the entries in the proplist list for a specific `prop`.

  If the `prop` does not exist, returns the proplist list unchanged.
  Use `delete_first/2` to delete just the first entry in case of
  duplicated props.

  ## Examples

      iex> Proplist.delete([{"a", 1}, {"b", 2}], "a")
      [{"b", 2}]

      iex> Proplist.delete([{"a", 1}, {"b", 2}, {"a", 3}], "a")
      [{"b", 2}]

      iex> Proplist.delete([{"b", 2}], "a")
      [{"b", 2}]

  """
  @spec delete(t, prop) :: t
  def delete(proplist, prop) when is_list(proplist) and is_binary(prop) do
    :lists.filter(fn {k, _} -> k != prop end, proplist)
  end

  @doc """
  Deletes the first entry in the proplist list for a specific `prop`.

  If the `prop` does not exist, returns the proplist list unchanged.

  ## Examples

      iex> Proplist.delete_first([{"a", 1}, {"b", 2}, {"a", 3}], "a")
      [{"b", 2}, {"a", 3}]

      iex> Proplist.delete_first([{"b", 2}], "a")
      [{"b", 2}]

  """
  @spec delete_first(t, prop) :: t
  def delete_first(proplist, prop) when is_list(proplist) and is_binary(prop) do
    :lists.keydelete(prop, 1, proplist)
  end

  @doc """
  Puts the given `value` under `prop`.

  If a previous value is already stored, all entries are
  removed and the value is overridden.

  ## Examples

      iex> Proplist.put([{"a", 1}, {"b", 2}], "a", 3)
      [{"a", 3}, {"b", 2}]

      iex> Proplist.put([{"a", 1}, {"b", 2}, {"a", 4}], "a", 3)
      [{"a", 3}, {"b", 2}]

  """
  @spec put(t, prop, value) :: t
  def put(proplist, prop, value) when is_list(proplist) and is_binary(prop) do
    [{prop, value}|delete(proplist, prop)]
  end

  @doc """
  Puts the given `value` under `prop` unless the entry `prop`
  already exists.

  ## Examples

      iex> Proplist.put_new([{"a", 1}], "b", 2)
      [{"b", 2}, {"a", 1}]

      iex> Proplist.put_new([{"a", 1}, {"b", 2}], "a", 3)
      [{"a", 1}, {"b", 2}]

  """
  @spec put_new(t, prop, value) :: t
  def put_new(proplist, prop, value) when is_list(proplist) and is_binary(prop) do
    case :lists.keyfind(prop, 1, proplist) do
      {^prop, _} -> proplist
      false -> [{prop, value}|proplist]
    end
  end

  @doc """
  Checks if two proplists are equal.

  Two proplists are considered to be equal if they contain
  the same props and those props contain the same values.

  ## Examples

      iex> Proplist.equal?([{"a", 1}, {"b", 2}], [{"b", 2}, {"a", 1}])
      true

  """
  @spec equal?(t, t) :: boolean
  def equal?(left, right) when is_list(left) and is_list(right) do
    :lists.sort(left) == :lists.sort(right)
  end

  @doc """
  Merges two proplist lists into one.

  If they have duplicated props, the one given in the second argument wins.

  ## Examples

      iex> Proplist.merge([{"a", 1}, {"b", 2}], [{"a", 3}, {"d", 4}]) |> Enum.sort
      [{"a", 3}, {"b", 2}, {"d", 4}]

  """
  @spec merge(t, t) :: t
  def merge(d1, d2) when is_list(d1) and is_list(d2) do
    fun = fn {k, _v} -> not has_prop?(d2, k) end
    d2 ++ :lists.filter(fun, d1)
  end

  @doc """
  Merges two proplist lists into one.

  If they have duplicated props, the given function is invoked to solve conflicts.

  ## Examples

      iex> Proplist.merge([{"a", 1}, {"b", 2}], [{"a", 3}, {"d", 4}], fn (_k, v1, v2) ->
      ...>   v1 + v2
      ...> end)
      [{"a", 4}, {"b", 2}, {"d", 4}]

  """
  @spec merge(t, t, (prop, value, value -> value)) :: t
  def merge(d1, d2, fun) when is_list(d1) and is_list(d2) do
    do_merge(d2, d1, fun)
  end

  defp do_merge([{k, v2}|t], acc, fun) do
    do_merge t, update(acc, k, v2, fn(v1) -> fun.(k, v1, v2) end), fun
  end

  defp do_merge([], acc, _fun) do
    acc
  end

  @doc """
  Returns whether a given `prop` exists in the given `proplist`.

  ## Examples

      iex> Proplist.has_prop?([{"a", 1}], "a")
      true

      iex> Proplist.has_prop?([{"a", 1}], "b")
      false

  """
  @spec has_prop?(t, prop) :: boolean
  def has_prop?(proplist, prop) when is_list(proplist) and is_binary(prop) do
    :lists.keymember(prop, 1, proplist)
  end

  @doc """
  Updates the `prop` with the given function.

  If the `prop` does not exist, raises `KeyError`.

  If there are duplicated props, they are all removed and only the first one
  is updated.

  ## Examples

      iex> Proplist.update!([{"a", 1}], "a", &(&1 * 2))
      [{"a", 2}]

      iex> Proplist.update!([{"a", 1}], "b", &(&1 * 2))
      ** (KeyError) key "b" not found in: [{"a", 1}]

  """
  @spec update!(t, prop, (value -> value)) :: t | no_return
  def update!(proplist, prop, fun) do
    update!(proplist, prop, fun, proplist)
  end

  defp update!([{prop, value}|proplist], prop, fun, _dict) do
    [{prop, fun.(value)}|delete(proplist, prop)]
  end

  defp update!([{_, _} = e|proplist], prop, fun, dict) do
    [e|update!(proplist, prop, fun, dict)]
  end

  defp update!([], prop, _fun, dict) when is_binary(prop) do
    raise(KeyError, key: prop, term: dict)
  end

  @doc """
  Updates the `prop` with the given function.

  If the `prop` does not exist, inserts the given `initial` value.

  If there are duplicated props, they are all removed and only the first one
  is updated.

  ## Examples

      iex> Proplist.update([{"a", 1}], "a", 13, &(&1 * 2))
      [{"a", 2}]

      iex> Proplist.update([{"a", 1}], "b", 11, &(&1 * 2))
      [{"a", 1}, {"b", 11}]

  """
  @spec update(t, prop, value, (value -> value)) :: t
  def update([{prop, value}|proplist], prop, _initial, fun) do
    [{prop, fun.(value)}|delete(proplist, prop)]
  end

  def update([{_, _} = e|proplist], prop, initial, fun) do
    [e|update(proplist, prop, initial, fun)]
  end

  def update([], prop, initial, _fun) when is_binary(prop) do
    [{prop, initial}]
  end

  @doc """
  Takes all entries corresponding to the given props and extracts them into a
  separate proplist list.

  Returns a tuple with the new list and the old list with removed props.

  Keys for which there are no entires in the proplist list are ignored.

  Entries with duplicated props end up in the same proplist list.

  ## Examples

      iex> d = [{"a", 1}, {"b", 2}, {"c", 3}, {"d", 4}]
      iex> Proplist.split(d, ["a", "c", "e"])
      {[{"a", 1}, {"c", 3}], [{"b", 2}, {"d", 4}]}

      iex> d = [{"a", 1}, {"b", 2}, {"c", 3}, {"d", 4}, {"e", 5}]
      iex> Proplist.split(d, ["a", "c", "e"])
      {[{"a", 1}, {"c", 3}, {"e", 5}], [{"b", 2}, {"d", 4}]}

  """
  def split(proplist, props) when is_list(proplist) do
    fun = fn {k, v}, {take, drop} ->
      case k in props do
        true  -> {[{k, v}|take], drop}
        false -> {take, [{k, v}|drop]}
      end
    end

    acc = {[], []}
    {take, drop} = :lists.foldl(fun, acc, proplist)
    {:lists.reverse(take), :lists.reverse(drop)}
  end

  @doc """
  Takes all entries corresponding to the given props and returns them in a new
  proplist list.

  Duplicated props are preserved in the new proplist list.

  ## Examples

      iex> d = [{"a", 1}, {"b", 2}, {"c", 3}, {"d", 4}]
      iex> Proplist.take(d, ["a", "c", "e"])
      [{"a", 1}, {"c", 3}]

      iex> d = [{"a", 1}, {"b", 2}, {"c", 3}, {"d", 4}, {"e", 5}]
      iex> Proplist.take(d, ["a", "c", "e"])
      [{"a", 1}, {"c", 3}, {"e", 5}]

  """
  def take(proplist, props) when is_list(proplist) do
    :lists.filter(fn {k, _} -> k in props end, proplist)
  end

  @doc """
  Drops the given props from the proplist list.

  Duplicated props are preserved in the new proplist list.

  ## Examples

      iex> d = [{"a", 1}, {"b", 2}, {"c", 3}, {"d", 4}]
      iex> Proplist.drop(d, ["b", "d"])
      [{"a", 1}, {"c", 3}]

      iex> d = [{"a", 1}, {"b", 2}, {"c", 3}, {"d", 4}, {"e", 5}]
      iex> Proplist.drop(d, ["b", "d"])
      [{"a", 1}, {"c", 3}, {"e", 5}]

  """
  def drop(proplist, props) when is_list(proplist) do
    :lists.filter(fn {k, _} -> not k in props end, proplist)
  end

  @doc """
  Returns the first value associated with `prop` in the proplist
  list as well as the proplist list without `prop`.

  All duplicated props are removed. See `pop_first/3` for
  removing only the first entry.

  ## Examples

      iex> Proplist.pop [{"a", 1}], "a"
      {1,[]}

      iex> Proplist.pop [{"a", 1}], "b"
      {nil,[{"a", 1}]}

      iex> Proplist.pop [{"a", 1}], "b", 3
      {3,[{"a", 1}]}

      iex> Proplist.pop [{"a", 1}], "b", 3
      {3,[{"a", 1}]}

      iex> Proplist.pop [{"a", 1}, {"a", 2}], "a"
      {1,[]}

  """
  def pop(proplist, prop, default \\ nil) when is_list(proplist) do
    {get(proplist, prop, default), delete(proplist, prop)}
  end

  @doc """
  Returns the first value associated with `prop` in the proplist
  list as well as the proplist list without that particular occurrence
  of `prop`.

  Duplicated props are not removed.

  ## Examples

      iex> Proplist.pop_first [{"a", 1}], "a"
      {1,[]}

      iex> Proplist.pop_first [{"a", 1}], "b"
      {nil,[{"a", 1}]}

      iex> Proplist.pop_first [{"a", 1}], "b", 3
      {3,[{"a", 1}]}

      iex> Proplist.pop_first [{"a", 1}], "b", 3
      {3,[{"a", 1}]}

      iex> Proplist.pop_first [{"a", 1}, {"a", 2}], "a"
      {1,[{"a", 2}]}

  """
  def pop_first(proplist, prop, default \\ nil) when is_list(proplist) do
    {get(proplist, prop, default), delete_first(proplist, prop)}
  end

  # Dict callbacks

  @doc false
  def keys(proplist) when is_list(proplist) do
    props(proplist)
  end

  @doc false
  def has_key?(proplist, prop) when is_list(proplist) do
    has_prop?(proplist, prop)
  end

  @doc false
  def size(proplist) do
    length(proplist)
  end

  @doc false
  def to_list(proplist) do
    proplist
  end
end
