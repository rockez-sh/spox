defmodule Core.Model.Config do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "cog" do
    field :name, :string
    field :value, :binary
    field :version, :integer
    field :schema_id, :string
    field :collection_id, :string
    field :latest, :boolean
    field :datatype, :string
    timestamps()
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [
      :name,
      :value,
      :schema_id,
      :collection_id,
      :version,
      :latest,
      :datatype
    ])
    |> validate_required([:name, :value])
    |> unique_constraint(:cog, name: :config_name_version_unique_index)
  end
end
