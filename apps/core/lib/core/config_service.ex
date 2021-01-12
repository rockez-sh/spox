defmodule Core.ConfigService do
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
         |> run(:validate_schema, &validate_schema/1, attrs)
         |> run(:define_default, &define_default_value/1)
         |> run(:defined_changeset, &define_changeset/1) do
      {:ok, %{defined_changeset: changeset}} ->
        case check_diff(changeset) do
          {:ok} ->
            case Multi.new()
                 |> Multi.insert(:saving_cog, changeset)
                 |> Multi.run(:old_cog, &promote_latest/2)
                 |> Multi.run(:promote_collection, &promote_collection/2)
                 |> Multi.run(:redis_copy, &copy_to_redis/2)
                 |> Repo.transaction() do
              {:ok, %{saving_cog: saving_cog}} ->
                {:ok, saving_cog}

              {:error, :saving_cog, repo, _} ->
                {:error, :saving_cog, repo}

              {:error, _, error_message, _} ->
                {:error, error_message}
            end

          {:duplicated, cs} ->
            {:ok, cs}
        end

      {:error, state, error} ->
        {:error, state, error}
    end
  end

  def as_json(%ConfigModel{} = changeset) do
    %{
      id: changeset.id,
      version: changeset.version,
      value: changeset.value,
      name: changeset.name,
      schema: changeset |> schema_name!,
      namespace: changeset.namespace
    }
  end

  def as_json([%ConfigModel{} = head | rest]) do
    ([head] ++ rest) |> Enum.map(&as_json_search_result/1)
  end

  def as_json([]), do: []

  defp as_json_search_result(changeset) do
    %{
      id: changeset.id,
      version: changeset.version,
      name: changeset.name,
      namespace: changeset.namespace
    }
  end

  def find(name, namespace \\ "default") do
    ConfigModel
    |> where([c], c.name == ^name)
    |> where([c], c.namespace == ^namespace)
    |> where([c], c.latest == true)
    |> Repo.one()
  end

  def get_version(name, namespace \\ "default") do
    case Redis.command(:get, "cog:ver:#{namespace}.#{name}") do
      {:ok, nil} ->
        case find(name, namespace) do
          nil ->
            {:ok, nil}

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
          nil ->
            {:ok, nil}

          cs ->
            copy_to_redis(cs)
            {:ok, cs.value}
        end

      {:ok, val} ->
        {:ok, val}
    end
  end

  def search(query, page \\ 1, per_page \\ 10)

  def search(%Ecto.Query{} = query, page, per_page) do
    page_offset = (page - 1) * per_page

    query
    |> select([:name, :namespace, :version, :id])
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
      ConfigModel
      |> pif(length(term_search) > 0, fn x ->
        x
        |> where([c], ^term_search)
      end)
      |> pif(keyword != nil, fn x ->
        x
        |> where([c], like(c.name, ^keyword))
      end)
      |> search(page, per_page)
    end
  end

  defp schema_name!(changeset) do
    case changeset.schema_id do
      nil -> nil
      sch_id -> Repo.get(SchemaConfig, sch_id).name
    end
  end

  defp define_default_value(%{validate_schema: attrs}) do
    {:ok,
     attrs
     |> Map.put(:latest, true)
     |> Map.put(:version, DateTime.utc_now() |> DateTime.to_unix(:millisecond))}
  end

  defp define_changeset(%{define_default: attrs}) do
    attrs = Map.put(attrs, :value, demod(attrs[:value]))
    {:ok, ConfigModel.changeset(%ConfigModel{}, attrs)}
  end

  defp promote_latest(repo, %{saving_cog: changeset}) do
    case ConfigModel
         |> where([c], c.id != ^changeset.id)
         |> where([c], c.name == ^changeset.name)
         |> where([c], c.latest == true)
         |> repo.one() do
      nil ->
        {:ok, nil}

      prev_version ->
        case prev_version
             |> ConfigModel.changeset(%{latest: false})
             |> repo.update do
          {:ok, _} -> {:ok, prev_version}
          {:error, _} -> {:error, "fail to update"}
        end
    end
  end

  defp promote_collection(repo, %{saving_cog: changeset, old_cog: %ConfigModel{} = prev_version}) do
    Ecto.assoc(prev_version, :collections)
    |> repo.all()
    |> Enum.each(fn col -> CollectionService.add_config(repo, col, [changeset]) end)

    {:ok, :ok}
  end

  defp promote_collection(_repo, _any), do: {:ok, :ok}

  defp validate_schema(%{schema: schema_name, value: value} = attrs) do
    case from(s in SchemaConfig, where: s.name == ^schema_name) |> Repo.one() do
      nil ->
        {:error, :schema_not_found}

      schema ->
        Logger.info("Schema Found")

        case schema.value
             |> Poison.decode!()
             |> ExJsonSchema.Schema.resolve()
             |> ExJsonSchema.Validator.validate(value |> normalize_value |> Poison.decode!()) do
          :ok ->
            attrs = attrs |> Map.delete(:schema) |> Map.put(:schema_id, schema.id)
            {:ok, attrs}

          {:error, detail_error} ->
            {:error, detail_error}
        end
    end
  end

  defp validate_schema(attrs), do: {:ok, attrs}

  defp normalize_value(value) when is_integer(value), do: "#{value}"
  defp normalize_value(value), do: value

  defp copy_to_redis(changeset) do
    commands = [
      ["SET", "cog:val:#{changeset.namespace}.#{changeset.name}", changeset.value],
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

  defp check_diff(new_cs) do
    if new_cs.valid? do
      %{name: name, namespace: namespace, value: value} = new_cs.changes

      case find(name, namespace) do
        nil ->
          {:ok}

        cs ->
          if demod(value) == cs.value do
            {:duplicated, cs}
          else
            {:ok}
          end
      end
    else
      {:ok}
    end
  end

  defp demod(value) when is_integer(value), do: value

  defp demod(value) do
    if String.match?(value |> String.trim(), ~r/^(\{.*\}|\[.*\])\s?$/ms) do
      value
      |> Poison.decode!()
      |> Poison.encode!()
    else
      value
    end
  end

  # defp promote_latest(created_config) do
  # end
end
