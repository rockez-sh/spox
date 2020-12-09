defmodule Core.Model.Collection do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "col" do
    field :name, :string
    field :version, :integer
    field :namespace, :string
    field :desc, :string
    timestamps()
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [
      :name,
      :namespace,
      :version,
      :desc
    ])
    |> validate_required([:name, :namespace, :desc, :version])
    |> unique_constraint([:name, :namespace])
  end
end
