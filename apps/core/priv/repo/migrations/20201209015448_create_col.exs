defmodule Core.Repo.Migrations.CreateCol do
  use Ecto.Migration

  def change do
    create table(:col,  primary_key: false) do
      add :id, :uuid, primary: true
      add :name, :string, null: false
      add :namespace, :string, null: false
      add :desc, :string
      add :version, :bigint, null: false
      timestamps()
    end
    create(unique_index(:col, [:id]))
    create(unique_index(:col, [:name, :namespace]))
  end
end
