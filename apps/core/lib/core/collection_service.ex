defmodule Core.CollectionService do
  alias Core.Model.Collection
  alias Core.Model.Config
  alias Core.Repo
  alias Ecto.Multi
  alias Core.Redis
  import Ecto.Query
  import Core.Utils

  def create(attrs \\ %{}) do
    case find(attrs |> Map.fetch!(:name), attrs |> Map.fetch!(:namespace)) do
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

  def as_json(changeset) do
    %{
      version: changeset.version,
      name: changeset.name,
      desc: changeset.desc
    }
  end

  def get_version(name, namespace \\ "default") do
    case Redis.command(:get, "col:ver:#{namespace}.#{name}") do
      {:ok, nil} ->
        case find(name, namespace) do
          nil -> {:ok, nil}
          cs ->
            case copy_to_redis(cs) do
              {:ok, _} -> {:ok, cs.version}
              {:error, message} -> {:error, message} 
            end
            {:ok, cs.version}
        end
      {:ok, val} ->
        {intVer, _} = Integer.parse(val)
        {:ok, intVer}
    end
  end

  def search(query, page \\ 1, per_page \\ 10)

  def search(%Ecto.Query{} = query, page, per_page) do
    page_offset = (page-1) * per_page
    query
    |> select([:name, :desc, :namespace, :version, :id])
    |> limit(^per_page)
    |> offset(^page_offset)
    |> Repo.all
  end

  def search(term, page, per_page) when is_map(term) do
    term_search = map_to_keyword(term, [:name, :namespace])
    if length(term_search) > 0 do
      Collection
      |> where([c], ^term_search)
      |> search(page, per_page)
    else
      []
    end
  end

  def search(term, page, per_page) when is_binary(term) do
    search_term = "%#{term}%"
    Collection
    |> where([c], like(c.name , ^search_term))
    |> or_where([c],  like(c.desc , ^search_term))
    |> search(page, per_page)
  end

  defp copy_to_redis(_repo, %{updated_col: col, cog: cog}) do
    commands = [
      ["SET", "col:ver:#{col.namespace}.#{col.name}", col.version],
      ["HSET", "col:val:#{col.namespace}.#{col.name}", cog.name, cog.value]
    ]
    case Redis.transaction_pipeline(commands) do
      {:ok, _} -> {:ok, col}
      {:error, message} -> {:error, message}
    end
  end

  defp copy_to_redis(col) do
    cmds = [["SET", "col:ver:#{col.namespace}.#{col.name}", col.version]]
    cog_cmds = Config
     |> where([c], c.collection_id == ^col.id)
     |> Repo.all
     |> Enum.map(fn(cog) -> ["HSET", "col:val:#{col.namespace}.#{col.name}", cog.name, cog.value] end)
    cmds = cmds ++ cog_cmds
    case Redis.transaction_pipeline(cmds) do
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