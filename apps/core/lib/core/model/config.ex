defmodule Core.Model.Config do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "cog" do
    field(:name, :string)
    field(:value, :binary)
    field(:version, :integer)
    field(:schema_id, :string)
    field(:collection_id, :string)
    field(:latest, :boolean)
    field(:datatype, :string)
    field(:namespace, :string)
    timestamps()
  end

  def changeset(struct, params) do
    params =
      params
      |> normalize_value
      |> Map.put(:datatype, "object")

    struct
    |> cast(params, [
      :name,
      :value,
      :schema_id,
      :collection_id,
      :version,
      :latest,
      :datatype,
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
