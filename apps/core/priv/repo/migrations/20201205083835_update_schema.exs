defmodule Core.Repo.Migrations.UpdateSchema do
  use Ecto.Migration

  def change do
    create(unique_index(:sch, [:id]))
    alter table(:sch) do
      add :namespace, :string, null: false, default: "default"
    end
  end
end
