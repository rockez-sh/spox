defmodule Core.ConfigTest do
  use ExUnit.Case, async: false
  alias Core.Fixture
  alias Core.Config
  alias Core.Model
  use Core.DataCase
  alias Core.Repo
  import Ecto.Query

  import Mock

  test "validate attrs" do
    f = Fixture.cog_string_valid()
    {_, f} = Map.pop(f, :namespace)
    {:error, x} = f |> Config.create
    assert x == "namespace must be defined"
  end

  test "define default value" do
    {:ok, cs} =  Config.create(Fixture.cog_string_valid())
    assert cs.version > 0
    assert cs.latest == true
    assert cs.inserted_at > 0
  end

  test "promote new version" do

    {:ok, cs1} =  Fixture.cog_string_valid() |> Config.create
    {:ok, cs1a} = Fixture.cog_string_valid() |> Map.put(:name, "merchant_email_receiver_weekday") |> Config.create
    {:ok, cs2} =  Fixture.cog_string_valid() |> Map.put(:value, "ops@newdomain.com") |> Config.create

    old_version = Repo.get_by(Core.Model.Config, id: cs1.id)
    another_config = Repo.get_by(Core.Model.Config, id: cs1a.id)

    assert cs1.version < cs2.version
    assert cs2.latest == true
    assert old_version.latest == false
    assert another_config.latest == true
  end

  test "validate with schema" do
    {:ok, schema_cs} = %Model.Schema{}
      |> Model.Schema.changeset(Fixture.schema_object)
      |> Repo.insert()

    {:ok, cfg} = Config.create(Fixture.cog_object_valid)
    assert cfg.schema_id == schema_cs.id

    assert {:error, "invalid payload agains json schema"} == Fixture.cog_object_json_schema_invalid |> Config.create()
    assert {:error, "Cannot find the schema"} == Fixture.cog_object_json_schema_invalid |> Map.put(:schema, "not_exist_schema") |> Config.create()
  end

  test "creating cog happen in transactional" do
    {:ok, _} = Fixture.cog_string_valid |> Config.create
    with_mock Core.Repo, [:passthrough], [update_all: fn(_, _) -> {:error, "DB CONNECT REFUSED" } end ] do
      {:error, m} = Fixture.cog_string_valid |> Map.put(:value, "ops2@example.com") |> Config.create()
      assert m == "DB CONNECT REFUSED"
      assert 1 == Repo.one(from p in Model.Config, select: count(p.id))
    end
  end

  test "make copy in redis" do
    fixture = %{
      name: "merchant_email_receiver",
      value: "ops@example.com",
      datatype: "string",
      namespace: "default"
    }
  end
end