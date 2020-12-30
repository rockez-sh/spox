defmodule Core.Repo.Migrations.AddDescToCogAndSchema do
  use Ecto.Migration

  def change do
    alter table("cog") do
      add :desc, :string
    end
    alter table("sch") do
      add :desc, :string
    end
  end
end
