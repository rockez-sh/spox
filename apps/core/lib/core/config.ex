defmodule Core.Config do
  alias Ecto.Multi
  alias Core.Repo
  alias Core.Model.Config, as: ConfigModel
  alias Core.Model.Schema, as: SchemaConfig
  import Ecto.Query
  import Logger
  def create(attrs \\ %{}) do

    case attrs
      |> validate_schema()
      |> validate_attribute()
      |> define_default_value()
      |> define_changeset() do
      {:ok, changeset} ->
        case Multi.new()
          |> Multi.insert(:inserted_cog, changeset)
          |> Multi.run(:old_cog, &promote_latest/2)
          |> Repo.transaction() do
            {:ok, %{inserted_cog: inserted_cog}} -> {:ok, inserted_cog}
            {:error, :old_cog, error_message, _} ->
              {:error, error_message}
            {:error, :inserted_cog, error_message, _} ->
              {:error, error_message}
          end
      {:error, error} -> {:error, error}
    end
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


  # defp promote_latest(created_config) do
  # end
end