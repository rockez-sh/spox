defmodule Core.Repo.Migrations.CreateScheme do
  use Ecto.Migration

  def change do
    create table(:sch,  primary_key: false) do
      add :id, :uuid, primary: true, null: false
      add :name, :string, null: false
      add :value, :binary, null: false
      timestamps()
    end
    create(unique_index(:sch, [:name], name: :schema_name_unique_index))
  end
end
