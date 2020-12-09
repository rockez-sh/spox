defmodule Core.ConfigTest do
  use ExUnit.Case, async: false
  alias Core.Fixture
  alias Core.Config
  alias Core.Model
  use Core.DataCase
  alias Core.Repo
  import Ecto.Query
  alias Core.SchemaService

  import Mock

  setup do
    Fixture.schema_object |> SchemaService.create
    :ok
  end
  test "validate attrs" do
    f = Fixture.cog_string_valid()
    {_, f} = Map.pop(f, :namespace)
    {:error, :saving_cog, cs} = f |> Config.create
    {msg, _} = cs.errors[:namespace]
    assert msg == "can't be blank"
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
    schema_cs = Model.Schema |> first |> Repo.one
    {:ok, cfg} = Config.create(Fixture.cog_object_valid)
    assert cfg.schema_id == schema_cs.id

    assert {:error, :validate_schema, [{"Type mismatch. Expected Integer but got String.", "#/attr_number"}]} == Fixture.cog_object_json_schema_invalid |> Config.create()
    assert {:error, :validate_schema, :schema_not_found} == Fixture.cog_object_json_schema_invalid |> Map.put(:schema, "not_exist_schema") |> Config.create()
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
    with_mock Core.Redis, [:passthrough], [] do
      {:ok, cs} = Fixture.cog_string_valid |> Config.create
      commands = [
        ["SET", "cog:val:#{cs.namespace}.#{cs.name}", cs.value],
        ["SET", "cog:ver:#{cs.namespace}.#{cs.name}", cs.version],
      ]
      assert_called Core.Redis.transaction_pipeline(commands)
    end
  end

  test "when copy to redis fail" do
    with_mock Core.Redis, [:passthrough], [transaction_pipeline: fn(_) -> {:error, "REDIS DISCONNECTED"} end] do
      {:error, error_message} = Fixture.cog_string_valid |> Config.create
      assert error_message == "REDIS DISCONNECTED"
      assert Repo.one(from p in Model.Config, select: count(p.id)) == 0
    end
  end

  test "as_json" do
    sch = Model.Schema |> first |> Repo.one
    {:ok, cfg} = Fixture.cog_object_valid
    |> Config.create
   assert %{name: cfg.name, version: cfg.version, value: cfg.value, schema: sch.name} == cfg |> Config.as_json
  end

  test "find" do
    fixture = Fixture.cog_object_valid
    %Model.Config{}
    |> Model.Config.changeset(fixture |> Map.put(:version, 1) |> Map.put(:latest, false))
    |> Repo.insert

    %Model.Config{}
    |> Model.Config.changeset(fixture |> Map.put(:version, 2) |> Map.put(:latest, true))
    |> Repo.insert

    latest = Config.find(fixture |> Map.fetch!(:name))
    assert latest.version == 2
  end

  test "upserting" do
    fixture = Fixture.cog_string_valid
    fixture |> Map.put(:value, "old@mail.com") |> Config.create
    fixture |> Map.put(:value, "newest@mail.com") |> Config.create
    latest_cog = Config.find(fixture |> Map.fetch!(:name))
    assert latest_cog.value == "newest@mail.com"
    assert 2 == Core.Model.Config |> select([c], count(c.id)) |> Core.Repo.one
  end

  test "get_version" do
    fixture = Fixture.cog_string_valid
    {:ok, cs } = fixture |> Config.create
    {:ok, version } = Config.get_version(fixture |> Map.fetch!(:name))
    assert version == cs.version
  end

  test "get version not found in redis" do
    fixture = Fixture.cog_string_valid
    {:ok, cs } = fixture |> Config.create
    Core.Redis.command(:flushall)

    with_mock Core.Redis, [:passthrough], [] do
      {:ok, version } = Config.get_version(fixture |> Map.fetch!(:name))
      assert version == cs.version
      commands = [
        ["SET", "cog:val:#{cs.namespace}.#{cs.name}", cs.value],
        ["SET", "cog:ver:#{cs.namespace}.#{cs.name}", cs.version],
      ]
      assert_called Core.Redis.transaction_pipeline(commands)
    end
  end

  test "get_value" do
    fixture = Fixture.cog_string_valid
    {:ok, cs } = fixture |> Config.create
    {:ok, version } = Config.get_value(fixture |> Map.fetch!(:name))
    assert version == cs.value
  end

  test "get value not found in redis" do
    fixture = Fixture.cog_string_valid
    {:ok, cs } = fixture |> Config.create
    Core.Redis.command(:flushall)

    with_mock Core.Redis, [:passthrough], [] do
      {:ok, version } = Config.get_value(fixture |> Map.fetch!(:name))
      assert version == cs.value
      commands = [
        ["SET", "cog:val:#{cs.namespace}.#{cs.name}", cs.value],
        ["SET", "cog:ver:#{cs.namespace}.#{cs.name}", cs.version],
      ]
      assert_called Core.Redis.transaction_pipeline(commands)
    end
  end

  describe "with collection" do
    setup do
      col_name = "sample_collection"
      {:ok, col_cs} = Fixture.col_valid
      |> Map.put(:name, col_name)
      |> Core.CollectionService.create

      {:ok, col_name: col_name, col_cs: col_cs }
    end
    test "it should link to collection id", context do
      fixture = Fixture.cog_string_valid
      |> Map.put(:collection, context[:col_name])

      {:ok, cs } = fixture |> Config.create

      assert cs.collection_id == context[:col_cs].id
    end

    test "collection not found", context do
      fixture = Fixture.cog_string_valid
      |> Map.put(:collection, "not_exist_collection")
      {:error, :assign_collection, m } = fixture |> Config.create
      assert m == "collection not found"
    end
  end
end