defmodule Core.Config do
  alias Ecto.Multi
  alias Core.Repo
  alias Core.Model.Config, as: ConfigModel
  alias Core.Model.Schema, as: SchemaConfig
  alias Core.Redis
  import Ecto.Query
  require Logger

  def create(attrs \\ %{}) do
    case attrs
      |> validate_schema()
      |> define_default_value()
      |> define_changeset() do
      {:ok, changeset} ->
        case Multi.new()
          |> Multi.insert(:saving_cog, changeset)
          |> Multi.run(:old_cog, &promote_latest/2)
          |> Multi.run(:redis_copy, &copy_to_redis/2)
          |> Repo.transaction() do
            {:ok, %{saving_cog: saving_cog}} -> {:ok, saving_cog}
            {:error, :saving_cog, repo, _} ->
              {:error, :saving_cog, repo}
            {:error, _, error_message, _} ->
              {:error, error_message}
          end
      {:error, error}  ->
        {:error, error}
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

  defp schema_name!(changeset) do
    case changeset.schema_id do
      nil -> nil
      sch_id -> Repo.get(SchemaConfig, sch_id).name
    end
  end

  defp define_default_value({:ok, attrs})  do
    {:ok, attrs
    |> Map.put(:latest, true)
    |> Map.put(:version, DateTime.utc_now |> DateTime.to_unix(:millisecond))}
  end

  defp define_default_value({:error, validation_error}) do
    {:error, validation_error}
  end

  defp define_changeset({:ok, attrs}) do
    {:ok, ConfigModel.changeset(%ConfigModel{}, attrs)}
  end
  defp define_changeset({:error, validation_error}) do
    {:error, validation_error}
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

  defp validate_schema(%{schema: schema_name, value: value} = attrs) do
    case from(s in SchemaConfig, where: s.name == ^schema_name) |>Repo.one() do
      nil -> {:error, "Cannot find the schema"}
      schema ->
        Logger.info("Schema Found")
        case schema.value
          |> Poison.decode!
          |> ExJsonSchema.Schema.resolve()
          |> ExJsonSchema.Validator.valid?(value |> Poison.decode!) do
            true ->
              attrs = attrs |> Map.delete(:schema) |> Map.put(:schema_id, schema.id)
              {:ok, attrs}
            _ -> {:error, "invalid payload agains json schema"}
        end
    end
  end

  defp validate_schema(attrs) do
    {:ok, attrs}
  end

  defp copy_to_redis(_, %{saving_cog: changeset}) do
    case Redis.command(:set, "cog:val:#{changeset.namespace}.#{changeset.name}", changeset |> as_json |> Poison.encode! ) do
      {:ok, _} -> {:ok, changeset}
      {:error, m} -> {:error, m}
    end
  end


  # defp promote_latest(created_config) do
  # end
end