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
          |> Multi.insert(:inserted_cog, changeset)
          |> Multi.run(:old_cog, &promote_latest/2)
          |> Multi.run(:redis_copy, &copy_to_redis/2)
          |> Repo.transaction() do
            {:ok, %{inserted_cog: inserted_cog}} -> {:ok, inserted_cog}
            {:error, :inserted_cog, repo, _} ->
              case repo.valid? do
                false ->  {:error, :constraint_error, repo}
                true -> {:error, :uknown_error, repo}
              end
            {:error, _, error_message, _} ->
              {:error, error_message}
          end
      {:error, error}  ->
        {:error, error}
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

  defp promote_latest(repo, %{inserted_cog: changeset} ) do
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

  defp copy_to_redis(_, %{inserted_cog: changeset}) do
    case Redis.command(:set, "cog:val:#{changeset.namespace}.#{changeset.name}", %{version: changeset.version, value: changeset.value} |> Poison.encode! ) do
      {:ok, _} -> {:ok, changeset}
      {:error, m} -> {:error, m}
    end
  end


  # defp promote_latest(created_config) do
  # end
end