defmodule Core.Utils do
  def atomize_map(map) do
    map |> Map.new(fn {k, v} -> {String.to_atom(k), v} end)
  end

  def multi() do
    {:ok, %{}}
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

end