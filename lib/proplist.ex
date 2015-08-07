defmodule Proplist do
  @moduledoc """
  Proplist is a wrapper for the erlang proplist module.
  """

  def delete(proplist, prop) when is_list(proplist) and is_binary(prop) do
    :proplists.delete prop, proplist
  end

  def delete(proplist, prop, value) when is_list(proplist) and is_binary(prop) do
    :lists.filter fn {p, v} -> p != prop or v != value end, proplist
  end

  def delete_first(proplist, prop) when is_list(proplist) and is_binary(prop) do
    :lists.keydelete(prop, 1, proplist)
  end

  def drop(proplist, props) when is_list(proplist) and is_list(props) do
    :lists.filter fn {p, _} -> not p in props end, proplist
  end

  def equal?(left, right) when is_list(left) and is_list(right) do
    :lists.sort(left) == :lists.sort(right)
  end

  def fetch!(proplist, prop) when is_list(proplist) and is_binary(prop) do
    case :lists.keyfind(prop, 1, proplist) do
      {^prop, value} -> value
      false -> raise KeyError, key: prop, term: proplist
    end
  end

  def fetch(proplist, prop) when is_list(proplist) and is_binary(prop) do
    case :lists.keyfind(prop, 1, proplist) do
      {^prop, value} -> {:ok, value}
      false -> :error
    end
  end

  def get(proplist, prop, default \\ nil) when is_list(proplist) and is_binary(prop) do
    :proplists.get_value prop, proplist, default
  end

  def get_values(proplist, prop) when is_list(proplist) and is_binary(prop) do
    :proplists.get_all_values prop, proplist
  end

  def has_key?(proplist, prop) when is_list(proplist) and is_binary(prop) do
    :proplists.is_defined prop, proplist
  end

  defdelegate keys(proplist), to: :proplists, as: :get_keys

  def merge(d1, d2) when is_list(d1) and is_list(d2) do
    fun = fn {p, _} -> not has_key?(d2, p) end
    d2 ++ :lists.filter(fun, d1)
  end

  def merge(d1, d2, fun) when is_list(d1) and is_list(d2) do
    do_merge(d2, d1, fun)
  end

  defp do_merge([{k, v2}|t], acc, fun) do
    do_merge t, update(acc, k, v2, fn(v1) -> fun.(k, v1, v2) end), fun
  end

  defp do_merge([], acc, _fun) do
    acc
  end

  def new do
    []
  end

  def new(pairs) do
    pairs
    |> Enum.reduce [], fn {p, v}, proplist ->
      put(proplist, p, v)
    end
  end

  def new(pairs, transform) do
    pairs
    |> Enum.reduce [], fn i, proplist ->
      {p, v} = transform.(i)
      put(proplist, p, v)
    end
  end

  def pop(proplist, prop, default \\ nil) when is_list(proplist) and is_binary(prop) do
    {get(proplist, prop, default), delete(proplist, prop)}
  end

  def pop_first(proplist, prop, default \\ nil) when is_list(proplist) and is_binary(prop) do
    {get(proplist, prop, default), delete_first(proplist, prop)}
  end

  def put(proplist, prop, value) when is_list(proplist) and is_binary(prop) do
    [{prop, value}|delete(proplist, prop)]
  end

  def put_new(proplist, prop, value) when is_list(proplist) and is_binary(prop) do
    unless has_key?(proplist, prop), do: [{prop, value}|proplist]
  end

  defdelegate split(proplist, prop), to: :proplists

  def take(proplist, props) when is_list(proplist) and is_list(props) do
    :lists.filter fn {prop, _} -> prop in props end, proplist
  end

  defdelegate values(proplist), to: Keyword

  def update([{prop, value}|proplist], prop, _initial, fun) do
    [{prop, fun.(value)}|delete(proplist, prop)]
  end

  def update([{_, _} = e|proplist], prop, initial, fun) do
    [e|update(proplist, prop, initial, fun)]
  end

  def update([], prop, initial, _fun) when is_binary(prop) do
    [{prop, initial}]
  end

  def update!(proplist, key, fun) do
    update!(proplist, key, fun, proplist)
  end

  defp update!([{prop, value}|proplist], prop, fun, _dict) do
    [{prop, fun.(value)}|delete(proplist, prop)]
  end

  defp update!([{_, _} = e|proplist], prop, fun, dict) do
    [e|update!(proplist, prop, fun, dict)]
  end

  defp update!([], prop, _fun, dict) when is_binary(prop) do
    raise KeyError, key: prop, term: dict
  end
end
