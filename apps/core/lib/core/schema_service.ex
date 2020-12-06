defmodule Core.SchemaService do
  alias Core.Model.Schema
  alias Core.Repo

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
end