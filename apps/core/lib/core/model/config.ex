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
    struct
    |> cast(params |> Map.put(:datatype, "object"), [
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
end
