defmodule Core.Config do
  alias Ecto.Multi
  alias Core.Repo
  alias Core.Model.Config, as: ConfigModel
  alias Core.Model.Schema, as: SchemaConfig
  alias Core.CollectionService
  alias Core.Redis
  import Ecto.Query
  import Core.Utils
  require Logger

  def create(attrs \\ %{}) do
    case multi()
      |> run(:assign_collection, &assign_collection/1, attrs)
      |> run(:validate_schema, &validate_schema/1)
      |> run(:define_default, &define_default_value/1)
      |> run(:define_changeset, &define_changeset/1) do
      {:ok, %{define_changeset: changeset}} ->
        case Multi.new()
          |> Multi.insert(:saving_cog, changeset)
          |> Multi.run(:promote_collection, &promote_collection/2)
          |> Multi.run(:old_cog, &promote_latest/2)
          |> Multi.run(:redis_copy, &copy_to_redis/2)
          |> Repo.transaction() do
            {:ok, %{saving_cog: saving_cog}} -> {:ok, saving_cog}
            {:error, :saving_cog, repo, _} ->
              {:error, :saving_cog, repo}
            {:error, _, error_message, _} ->
              {:error, error_message}
          end
      {:error, state, error}  ->
        {:error, state, error}
    end
  end

  def as_json(changeset) do
    %{
      version: changeset.version,
      value: changeset.value,
      name: changeset.name,
      schema: changeset |> schema_name!
    }
  end

  def find(name, namespace \\ "default") do
    ConfigModel
    |> where([c], c.name == ^name)
    |> where([c], c.namespace == ^namespace)
    |> where([c], c.latest == true)
    |> Repo.one
  end

  def get_version(name, namespace \\"default") do
    case Redis.command(:get, "cog:ver:#{namespace}.#{name}") do
      {:ok, nil} ->
        case find(name, namespace) do
          nil -> {:ok, nil}
          cs ->
            copy_to_redis(cs)
            {:ok, cs.version}
        end
      {:ok, val} ->
        {intVer, _} = Integer.parse(val)
        {:ok, intVer}
    end
  end

  def get_value(name, namespace \\ "default") do
    case Redis.command(:get, "cog:val:#{namespace}.#{name}") do
      {:ok, nil} ->
        case find(name, namespace) do
          nil -> {:ok, nil}
          cs ->
            copy_to_redis(cs)
            {:ok, cs.value}
        end
      {:ok, val} -> {:ok, val}
    end
  end

  defp schema_name!(changeset) do
    case changeset.schema_id do
      nil -> nil
      sch_id -> Repo.get(SchemaConfig, sch_id).name
    end
  end

  defp define_default_value(%{validate_schema: attrs}) do
    {:ok, attrs
    |> Map.put(:latest, true)
    |> Map.put(:version, DateTime.utc_now |> DateTime.to_unix(:millisecond))}
  end

  defp define_changeset(%{define_default: attrs}) do
    {:ok, ConfigModel.changeset(%ConfigModel{}, attrs) }
  end

  defp promote_latest(repo, %{saving_cog: changeset} ) do
    case ConfigModel
    |> where([c], c.id != ^changeset.id)
    |> where([c], c.name == ^changeset.name)
    |> where([c], c.latest == true)
    |> repo.update_all(set: [latest: false]) do
      {:error, error} -> {:error, error}
      {1, nil} -> {:ok, changeset}
      _ -> {:ok, changeset}
    end
  end

  defp promote_collection(repo, %{saving_cog: changeset} ) do
    case changeset.collection_id do
      nil -> {:ok, :ok}
      cid ->
        col_cs = Core.Model.Collection |> Repo.get(cid)
        case CollectionService.touch(repo, col_cs) do
          {:ok, cs} -> {:ok, cs}
          {:error, message} -> {:error, message}
        end
    end
  end

  defp validate_schema(%{assign_collection: %{schema: schema_name, value: value} = attrs } ) do
    case from(s in SchemaConfig, where: s.name == ^schema_name) |>Repo.one() do
      nil -> {:error, :schema_not_found}
      schema ->
        Logger.info("Schema Found")
        case schema.value
          |> Poison.decode!
          |> ExJsonSchema.Schema.resolve()
          |> ExJsonSchema.Validator.validate(value |> Poison.decode!) do
            :ok ->
              attrs = attrs |> Map.delete(:schema) |> Map.put(:schema_id, schema.id)
              {:ok, attrs}
            {:error, detail_error} -> {:error, detail_error}
        end
    end
  end
  defp validate_schema(%{assign_collection: attrs}), do: {:ok, attrs}

  defp assign_collection(%{collection: collection_name, namespace: namespace} = attrs) do
    case collection_name do
      nil -> attrs
      "" -> attrs
      _ ->
        case CollectionService.find(collection_name, namespace) do
          nil -> {:error, "collection not found"}
          cs -> {:ok, attrs |> Map.put(:collection_id, cs.id) }
        end
    end
  end

  defp assign_collection(attrs), do: {:ok, attrs}

  defp copy_to_redis(changeset) do
    commands = [
      ["SET", "cog:val:#{changeset.namespace}.#{changeset.name}", changeset.value ],
      ["SET", "cog:ver:#{changeset.namespace}.#{changeset.name}", changeset.version]
    ]
    case Redis.transaction_pipeline(commands) do
      {:ok, _} -> {:ok, changeset}
      {:error, message} -> {:error, message}
    end
  end

  defp copy_to_redis(_, %{saving_cog: changeset}) do
    copy_to_redis(changeset)
  end


  # defp promote_latest(created_config) do
  # end
end