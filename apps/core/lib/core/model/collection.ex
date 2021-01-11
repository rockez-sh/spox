defmodule Core.Model.Collection do
  use Ecto.Schema
  alias Core.Model.Config
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "col" do
    field(:name, :string)
    field(:version, :integer)
    field(:namespace, :string)
    field(:desc, :string)

    many_to_many(
      :configs,
      Config,
      join_through: "cog_col_ref",
      on_replace: :delete,
      join_keys: [col_id: :id, cog_id: :id]
    )

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
