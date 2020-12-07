defmodule Core.SchemaService do
  alias Core.Model.Schema
  alias Core.Repo
  import Ecto.Query

  def create(attrs \\ %{}) do
    case Schema.changeset(%Schema{}, attrs)
    |> Repo.insert do
      {:ok, cs} -> {:ok, cs}
      {:error, cs} ->
        if !cs.valid? do
          {:error, :constraint_error, cs}
        else
          {:error, :unknow_error, cs}
        end
    end
  end

  def find(name) do
    Schema
    |> where([c], c.name == ^name)
    |> Repo.one
  end

  def as_json(schema) do
    %{name: schema.name, value: schema.value}
  end

end