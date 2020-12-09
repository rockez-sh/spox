defmodule Core.CollectionService do
  alias Core.Model.Collection
  alias Core.Repo
  alias Ecto.Multi
  alias Core.Redis
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

  def touch(repo, cs, cfg) do
    cs = Collection.changeset(cs, %{version: DateTime.utc_now |> DateTime.to_unix(:millisecond)})
    case Multi.new()
    |> Multi.run(:cog, fn(_, _) -> {:ok, cfg} end )
    |> Multi.update(:updated_col, cs)
    |> Multi.run(:copy_to_redis, &copy_to_redis/2)
    |> repo.transaction() do
      {:ok, %{updated_col: col}} -> {:ok, col}
      {:error, _, message} -> {:error, message}
    end
  end

  def find(name, namespace \\ "default") do
    Collection
    |> where([c], c.name == ^name)
    |> where([c], c.namespace == ^namespace)
    |> Repo.one
  end

  defp copy_to_redis(_repo, %{updated_col: col, cog: cog}) do
    commands = [
      ["SET", "ver:col:#{col.namespace}.#{col.name}", col.version],
      ["HSET", "val:col:#{col.namespace}.#{col.name}", cog.name, cog.value]
    ]
    case Redis.transaction_pipeline(commands) do
      {:ok, _} -> {:ok, col}
      {:error, message} -> {:error, message}
    end
  end

  def set_changeset(cs, attrs) do
    attrs = case cs.id do
      nil -> attrs |> Map.put(:version, 0)
      _ -> attrs
    end

    cs |> Collection.changeset(attrs)
  end
end