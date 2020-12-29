defmodule Core.Repo.Migrations.DropCogDatatype do
  use Ecto.Migration

  def change do
    alter table("cog") do
      remove :datatype
    end
  end
end
