defmodule Core.CollectionService do
  alias Core.Model.Collection
  alias Core.Repo
  import Ecto.Query
  import Core.Utils

  def create(attrs \\ %{}) do
    result = case find(attrs |> Map.fetch!(:name), attrs |> Map.fetch!(:namespace)) do
      nil -> %Collection{}
      cs -> cs
    end
    |> set_changeset(attrs)
    |> Repo.insert_or_update
  end

  def find(name, namespace \\ "default") do
    Collection
    |> where([c], c.name == ^name)
    |> where([c], c.namespace == ^namespace)
    |> Repo.one
  end

  def set_changeset(cs, attrs) do
    attrs = case cs.id do
      nil -> attrs |> Map.put(:version, 0)
      _ -> attrs
    end

    cs |> Collection.changeset(attrs)
  end
end