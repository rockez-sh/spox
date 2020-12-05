defmodule Core.Repo.Migrations.UpdateCogIdIndex do
  use Ecto.Migration

  def change do
    create(unique_index(:cog, [:id]))
  end
end
