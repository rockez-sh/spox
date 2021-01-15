defmodule Core.CollectionService do
  alias Core.Model.Collection
  alias Core.Model.Config
  alias Core.Repo
  alias Ecto.Multi
  alias Core.Redis
  import Ecto.Query
  import Core.Utils
  require Logger

  def create(attrs \\ %{}) do
    case find(attrs |> Map.fetch!(:name), attrs |> Map.fetch!(:namespace)) do
      nil -> %Collection{}
      cs -> cs
    end
    |> set_changeset(attrs)
    |> Repo.insert_or_update()
  end

  def touch(repo, cs, cfg) do
    cs =
      Collection.changeset(cs, %{version: DateTime.utc_now() |> DateTime.to_unix(:millisecond)})

    case Multi.new()
         |> Multi.run(:cog, fn _, _ -> {:ok, cfg} end)
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
    |> Repo.one()
  end

  def as_json(%Collection{} = changeset) do
    %{
      id: changeset.id,
      version: changeset.version,
      name: changeset.name,
      desc: changeset.desc,
      namespace: changeset.namespace,
      configs: changeset |> configs_as_json
    }
  end

  def as_json([%Collection{} = _head | _] = changesets) do
    changesets
    |> Enum.map(fn changeset ->
      %{
        id: changeset.id,
        version: changeset.version,
        name: changeset.name,
        desc: changeset.desc,
        namespace: changeset.namespace
      }
    end)
  end

  def as_json([]), do: []

  def get_version(name, namespace \\ "default") do
    case Redis.command(:get, "col:ver:#{namespace}.#{name}") do
      {:ok, nil} ->
        case find(name, namespace) do
          nil ->
            {:ok, nil}

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
    page_offset = (page - 1) * per_page

    query
    |> select([:name, :desc, :namespace, :version, :id])
    |> limit(^per_page)
    |> offset(^page_offset)
    |> Repo.all()
  end

  def search(term, page, per_page) when is_map(term) do
    keyword =
      case Map.fetch(term, :keyword) do
        {:ok, v} -> "%#{v}%"
        _ -> nil
      end

    term_search = map_to_keyword(term, [:name, :namespace])

    unless length(term_search) > 0 or keyword do
      []
    else
      Collection
      |> pif(length(term_search) > 0, fn x ->
        x
        |> where([c], ^term_search)
      end)
      |> pif(keyword != nil, fn x ->
        x
        |> where([c], like(c.name, ^keyword))
        |> or_where([c], like(c.desc, ^keyword))
      end)
      |> search(page, per_page)
    end
  end

  def add_config(coll_name, [], _namespace) when is_binary(coll_name),
    do: {:error, "no new config provided"}

  def add_config(coll_name, [head | _] = config_names, namespace)
      when is_binary(coll_name) and is_binary(head) do
    case Collection
         |> where([c], c.name == ^coll_name)
         |> where([c], c.namespace == ^namespace)
         |> Repo.one() do
      nil ->
        {:error, "Collection Not Found"}

      collection ->
        configs =
          Config
          |> where([c], c.name in ^config_names)
          |> where([c], c.latest == true)
          |> Repo.all()

        if length(configs) == length(config_names) do
          add_config(Repo, collection, configs)
        else
          config_db_names = configs |> Enum.map(fn x -> x.name end)
          not_found = config_names -- config_db_names
          not_found = not_found |> Enum.join(", ")
          {:error, "Cannot find config with name(s) #{not_found} "}
        end
    end
  end

  def add_config(repo, collection, configs) do
    collection =
      collection
      |> repo.preload(:configs)
      |> Collection.changeset(%{version: DateTime.utc_now() |> DateTime.to_unix(:millisecond)})
      |> Ecto.Changeset.put_assoc(:configs, configs)
      |> repo.update!

    copy_to_redis(repo, %{updated_col: collection, cog: configs})
    {:ok, collection}
  end

  def add_config(collection, configs) do
    add_config(Repo, collection, configs)
  end

  defp copy_to_redis(_repo, %{updated_col: col, cog: cogs}) do
    commands = [
      ["SET", "col:ver:#{col.namespace}.#{col.name}", col.version]
    ]

    cog_commands =
      cogs
      |> Enum.map(fn cog ->
        ["HSET", "col:val:#{col.namespace}.#{col.name}", cog.name, cog.value]
      end)

    commands = commands ++ cog_commands

    case Redis.transaction_pipeline(commands) do
      {:ok, _} -> {:ok, col}
      {:error, message} -> {:error, message}
    end
  end

  defp copy_to_redis(col) do
    cmds = [["SET", "col:ver:#{col.namespace}.#{col.name}", col.version]]
    col = col |> Repo.preload(:configs)

    cog_cmds =
      Ecto.assoc(col, :configs)
      |> where([c], c.latest == true)
      |> Repo.all()
      |> Enum.map(fn cog ->
        ["HSET", "col:val:#{col.namespace}.#{col.name}", cog.name, cog.value]
      end)

    cmds = cmds ++ cog_cmds

    case Redis.transaction_pipeline(cmds) do
      {:ok, _} -> {:ok, col}
      {:error, message} -> {:error, message}
    end
  end

  def set_changeset(cs, attrs) do
    attrs =
      case cs.id do
        nil -> attrs |> Map.put(:version, 0)
        _ -> attrs
      end

    cs |> Collection.changeset(attrs)
  end

  defp configs_as_json(col) do
    if col.version == 0 do
      []
    else
      case Redis.command("hgetall", ["col:val:#{col.namespace}.#{col.name}"]) do
        {:ok, result} when result != [] ->
          result
          |> Enum.chunk_every(2)
          |> Enum.map(&config_as_json/1)

        _ ->
          Logger.warn("Fail to fetch Redis cache for #{col.namespace}.#{col.name}")

          case copy_to_redis(col) do
            {:ok, _} -> configs_as_json(col)
            {:error, message} -> raise message
          end
      end
    end
  end

  defp config_as_json(%Config{} = cog) do
    %{
      name: cog.name,
      value: cog.value
    }
  end

  defp config_as_json([name, value]) do
    %{
      name: name,
      value: value
    }
  end
end
