defmodule Core.Model.Schema do
  use Ecto.Schema
  import Ecto.Changeset
  @primary_key {:id, :binary_id, autogenerate: true}

  schema "sch" do
    field(:name, :string)
    field(:value, :binary)
    timestamps()
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [
      :name,
      :value
    ])
    |> validate_required([:name, :value])
    |> unique_constraint(:sch, name: :schema_name_unique_index)
  end
end
