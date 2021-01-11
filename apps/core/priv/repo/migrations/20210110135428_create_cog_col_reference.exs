defmodule Core.Repo.Migrations.CreateCogColReference do
  use Ecto.Migration

  def up do
    alter table("cog") do
      remove :collection_id
    end

    create table(:cog_col_ref,  primary_key: false) do
      add(:cog_id, references(:cog, type: :uuid))
      add(:col_id, references(:col, type: :uuid))
      add(:inserted_at, :timestamp, default: fragment("NOW()"))
    end

    create(index(:cog_col_ref, [:cog_id]))
    create(index(:cog_col_ref, [:col_id]))
  end

  def down do
    alter table("cog") do
      add :collection_id, :string
    end

    drop(index(:cog_col_ref, [:cog_id]))
    drop(index(:cog_col_ref, [:col_id]))
    drop(table(:cog_col_ref))
  end
end
