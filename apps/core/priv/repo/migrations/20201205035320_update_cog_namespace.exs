defmodule Core.Repo.Migrations.UpdateCogNamespace do
  use Ecto.Migration

  def change do
    alter table("cog") do
      add :namespace, :string, null: false, default: "default"
    end
    create(unique_index(:cog, [:name, :namespace, :version]))
    drop(unique_index(:cog, [:name, :version], name: :config_name_version_unique_index))
  end
end
