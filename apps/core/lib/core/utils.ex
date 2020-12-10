defmodule Core.Utils do
  def atomize_map(map) do
    map |> Map.new(fn {k, v} -> {String.to_atom(k), v} end)
  end

  def multi() do
    {:ok, %{}}
  end

  def multi(args, state, func) do
    case func.(args) do
       {:ok, result } -> {:ok, %{} |> Map.put(state, result)}
       {:error, message} -> {:error, state, message}
    end
  end

  def run(prev, current_state, func, args) do
    run(prev, current_state, fn (state) -> func.(args) end  )
  end

  def run(prev, current_state, func, args, args2) do
    run(prev, current_state, fn (state) -> func.(args, args2) end  )
  end

  def run(prev, current_state, func, args, args2, args3) do
    run(prev, current_state, fn (state) -> func.(args, args2, args3) end  )
  end

  def run(prev, current_state, func) do
    case prev do
      {:ok, state} ->
        case func.(state) do
          {:ok, result} -> {:ok, state |> Map.put(current_state, result)}
          {:error, message} -> {:error, current_state, message}
        end
      {:error, error_state, message} when is_atom(error_state) ->
        {:error, error_state, message}
    end
  end

  def map_to_keyword(map, keys \\ []) do
    Enum.filter(map, fn({k, value}) -> Enum.any?(keys, fn(key)-> k == key end) end)
    |> Enum.map(fn({key, value}) -> {key, value} end)
  end

end