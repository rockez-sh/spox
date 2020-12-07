defmodule Core.Utils do
  def atomize_map(map) do
    map |> Map.new(fn {k, v} -> {String.to_atom(k), v} end)
  end
end