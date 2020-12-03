defmodule Core.Repo.Migrations.CreateCog do
  use Ecto.Migration

  def change do
    create table(:cog,  primary_key: false) do
      add :id, :uuid, primary: true
      add :datatype, :string, null: false
      add :name, :string, null: false
      add :value, :binary, null: false
      add :version, :bigint, null: false
      add :schema_id, :string, null: true
      add :collection_id, :string, null: true
      add :latest, :boolean, null: false

      timestamps()
    end

    create(unique_index(:cog, [:name, :version], name: :config_name_version_unique_index))
  end
end
