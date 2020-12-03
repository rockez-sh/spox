defmodule Core.Utils.Config do
  defmodule Transformer do
    def transform(value, _keys) do
      value
    end
  end

  def config(app, key) do
    Application.get_env(app, key)
    |> transform([app, key])
  end

  def config(app, key, sub_key) do
    Application.get_env(app, key)
    |> Keyword.get(sub_key)
    |> transform([app, key, sub_key])
  end

  def config(app, key, sub_key_a, sub_key_b) do
    Application.get_env(app, key)
    |> Keyword.get(sub_key_a)
    |> Keyword.get(sub_key_b)
    |> transform([app, key, sub_key_a, sub_key_b])
  end

  def config(app, key, sub_key_a, sub_key_b, sub_key_c) do
    Application.get_env(app, key)
    |> Keyword.get(sub_key_a)
    |> Keyword.get(sub_key_b)
    |> Keyword.get(sub_key_c)
    |> transform([app, key, sub_key_a, sub_key_b, sub_key_c])
  end

  defp transform(value, keys) do
    transformer = Application.get_env(:core, :config_transformer)
    transformer.transform(value, keys)
  end
end
