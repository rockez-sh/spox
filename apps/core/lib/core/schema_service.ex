defmodule Core.SchemaService do
  alias Core.Model.Schema
  alias Core.Repo
  import Ecto.Query
  import Core.Utils

  def create(attrs \\ %{}) do
    case multi()
    |> run(:parsed_json, &parse_json/1, attrs)
    |> run(:validate_schema, &validate_schema/1)
    |> run(:saving_schema, &insert_update_schema/1, attrs) do
      {:ok, %{saving_schema: schema}} -> {:ok, schema}
      {:error, state, error} -> {:error, state, error}
    end
  end

  def find(name) do
    Schema
    |> where([c], c.name == ^name)
    |> Repo.one
  end

  def search(query, page \\ 1, per_page \\ 10)

  def search(%Ecto.Query{} = query, page, per_page) do
    page_offset = (page-1) * per_page
    query
    |> select([:name, :id])
    |> limit(^per_page)
    |> offset(^page_offset)
    |> Repo.all
  end

  def search(term, page, per_page) when is_map(term) do
    keyword = case Map.fetch(term, :keyword) do
      {:ok, v} -> "%#{v}%"
      _ -> nil
    end
    term_search = map_to_keyword(term, [:name])

    unless length(term_search) > 0 or keyword do
      []
    else
      Schema
      |> pif(length(term_search) > 0, fn(x) ->
        x
        |> where([c], ^term_search)
      end)
      |> pif(keyword != nil, fn(x) ->
        x
        |> where([c], like(c.name, ^keyword))
      end)
      |> search(page, per_page)
    end
  end

  def as_json(schema) do
    %{name: schema.name, value: schema.value}
  end

  defp validate_schema(%{parsed_json: parsed_json}) do
    try do
      {:ok, parsed_json |> ExJsonSchema.Schema.resolve }
    rescue
      ExJsonSchema.Schema.InvalidSchemaError -> {:error, "Invalid JSON Schema"}
    end
  end

  defp insert_update_schema(attrs) do
    case find(attrs |> Map.fetch!(:name)) do
      nil -> %Schema{}
      cs -> cs
    end
    |> Schema.changeset(attrs)
    |> Repo.insert_or_update
  end

  defp parse_json(%{value: value}) do
    case value |> Poison.decode do
      {:ok, result} -> {:ok, result}
      {:error, _} -> {:error, "Invalid JSON" }
    end
  end
end