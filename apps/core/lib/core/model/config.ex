defmodule Core.Model.Config do
  use Ecto.Schema
  import Ecto.Changeset
  alias Core.Model.Collection

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "cog" do
    field(:name, :string)
    field(:value, :binary)
    field(:version, :integer)
    field(:schema_id, :string)
    field(:latest, :boolean)
    field(:desc, :string)
    field(:namespace, :string)

    many_to_many(
      :collections,
      Collection,
      join_through: "cog_col_ref",
      on_replace: :delete,
      join_keys: [col_id: :id, cog_id: :id]
    )

    timestamps()
  end

  def changeset(struct, params) do
    params =
      params
      |> normalize_value

    struct
    |> cast(params, [
      :name,
      :value,
      :schema_id,
      :version,
      :latest,
      :desc,
      :namespace
    ])
    |> validate_required([:name, :value, :namespace])
    |> unique_constraint([:name, :namespace, :version])
  end

  def normalize_value(%{value: value} = params) when is_number(value) do
    params |> Map.put(:value, "#{value}")
  end

  def normalize_value(params), do: params
end
