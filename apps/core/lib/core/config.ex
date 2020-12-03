defmodule Core.Config do
  alias Core.Repo
  alias Core.Model.Config, as: ConfigModel
  alias Core.Model.Schema, as: SchemaConfig
  import Ecto.Query
  import Logger
  def create(attrs \\ %{}) do
    attrs
    |> validate_schema()
    |> validate_attribute()
    |> define_default_value()
    |> define_changeset()
    |> insert_repo()
    |> promote_latest()
    # |> sync_with_redis()
  end

  defp validate_attribute({:ok, attrs}) do
    if attrs[:namespace] == nil do
      {:error, "namespace must be defined"}
    else
      {:ok, attrs}
    end
  end
  defp validate_attribute({:error, validation_error}) do
    {:error, validation_error}
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

  defp insert_repo({:ok, changeset}) do
    Repo.insert(changeset)
  end

  defp insert_repo({:error, validation_error}) do
    {:error, validation_error}
  end

  defp promote_latest({:ok, changeset}) do
    case ConfigModel
    |> where([c], c.id != ^changeset.id)
    |> where([c], c.name == ^changeset.name)
    |> where([c], c.latest == true)
    |> Repo.update_all(set: [latest: false]) do
      {:error, error} -> {:error, error}
      {1, nil} -> {:ok, changeset}
      _ -> {:ok, changeset}
    end
  end

  defp promote_latest({:error, changeset}) do
    {:error, changeset}
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


  # defp promote_latest(created_config) do
  # end
end