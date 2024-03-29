defmodule Core.ConfigTest do
  use ExUnit.Case, async: false
  alias Core.Fixture
  alias Core.ConfigService
  alias Core.Model
  use Core.DataCase
  alias Core.Repo
  import Ecto.Query
  alias Core.SchemaService
  require Logger

  import Mock

  setup do
    Fixture.schema_object() |> SchemaService.create()
    :ok
  end

  test "validate attrs" do
    f = Fixture.cog_string_valid()
    {_, f} = Map.pop(f, :namespace)
    {:error, :saving_cog, cs} = f |> ConfigService.create()
    {msg, _} = cs.errors[:namespace]
    assert msg == "can't be blank"
  end

  test "define default value" do
    {:ok, cs} = ConfigService.create(Fixture.cog_string_valid())
    assert cs.version > 0
    assert cs.latest == true
    assert cs.inserted_at > 0
  end

  test "promote new version" do
    {:ok, cs1} = Fixture.cog_string_valid() |> ConfigService.create()

    {:ok, cs1a} =
      Fixture.cog_string_valid()
      |> Map.put(:name, "merchant_email_receiver_weekday")
      |> ConfigService.create()

    {:ok, cs2} =
      Fixture.cog_string_valid() |> Map.put(:value, "ops@newdomain.com") |> ConfigService.create()

    old_version = Repo.get_by(Core.Model.Config, id: cs1.id)
    another_config = Repo.get_by(Core.Model.Config, id: cs1a.id)

    assert cs1.version < cs2.version
    assert cs2.latest == true
    assert old_version.latest == false
    assert another_config.latest == true
  end

  test "validate with schema" do
    schema_cs = Model.Schema |> first |> Repo.one()
    {:ok, cfg} = ConfigService.create(Fixture.cog_object_valid())
    assert cfg.schema_id == schema_cs.id

    assert {:error, :validate_schema,
            [{"Type mismatch. Expected Integer but got String.", "#/attr_number"}]} ==
             Fixture.cog_object_json_schema_invalid() |> ConfigService.create()

    assert {:error, :validate_schema, :schema_not_found} ==
             Fixture.cog_object_json_schema_invalid()
             |> Map.put(:schema, "not_exist_schema")
             |> ConfigService.create()
  end

  test "validate schema non object" do
    {:ok, schema_cs} = Fixture.schema_generic_number_above_100() |> SchemaService.create()

    {:ok, _} =
      ConfigService.create(%{
        name: "number_100",
        value: 100,
        namespace: "default",
        schema: schema_cs.name
      })

    {:error, stage, error} =
      ConfigService.create(%{
        name: "number_under_100",
        value: 99,
        namespace: "default",
        schema: schema_cs.name
      })

    assert stage == :validate_schema
    assert [{"Expected the value to be >= 100", "#"} | _] = error
  end

  test "creating cog happen in transactional" do
    {:ok, cs} = Fixture.cog_string_valid() |> ConfigService.create()

    with_mock Core.Repo, [:passthrough], update: fn _ -> {:error, cs} end do
      {:error, _} =
        Fixture.cog_string_valid()
        |> Map.put(:value, "ops2@example.com")
        |> ConfigService.create()

      assert 1 == Repo.one(from(p in Model.Config, select: count(p.id)))
    end
  end

  test "make copy in redis" do
    with_mock Core.Redis, [:passthrough], [] do
      {:ok, cs} = Fixture.cog_string_valid() |> ConfigService.create()

      commands = [
        ["SET", "cog:val:#{cs.namespace}.#{cs.name}", cs.value],
        ["SET", "cog:ver:#{cs.namespace}.#{cs.name}", cs.version]
      ]

      assert_called(Core.Redis.transaction_pipeline(commands))
    end
  end

  test "when copy to redis fail" do
    with_mock Core.Redis, [:passthrough],
      transaction_pipeline: fn _ -> {:error, "REDIS DISCONNECTED"} end do
      {:error, error_message} = Fixture.cog_string_valid() |> ConfigService.create()
      assert error_message == "REDIS DISCONNECTED"
      assert Repo.one(from(p in Model.Config, select: count(p.id))) == 0
    end
  end

  test "as_json" do
    sch = Model.Schema |> first |> Repo.one()

    {:ok, cfg} =
      Fixture.cog_object_valid()
      |> ConfigService.create()

    assert %{
             name: cfg.name,
             version: cfg.version,
             value: cfg.value,
             schema: sch.name,
             id: cfg.id,
             namespace: cfg.namespace
           } ==
             cfg |> ConfigService.as_json()
  end

  test "find" do
    fixture = Fixture.cog_object_valid()

    %Model.Config{}
    |> Model.Config.changeset(fixture |> Map.put(:version, 1) |> Map.put(:latest, false))
    |> Repo.insert()

    %Model.Config{}
    |> Model.Config.changeset(fixture |> Map.put(:version, 2) |> Map.put(:latest, true))
    |> Repo.insert()

    latest = ConfigService.find(fixture |> Map.fetch!(:name))
    assert latest.version == 2
  end

  test "upserting" do
    fixture = Fixture.cog_string_valid()
    fixture |> Map.put(:value, "old@mail.com") |> ConfigService.create()
    fixture |> Map.put(:value, "newest@mail.com") |> ConfigService.create()
    latest_cog = ConfigService.find(fixture |> Map.fetch!(:name))
    assert latest_cog.value == "newest@mail.com"
    assert 2 == Core.Model.Config |> select([c], count(c.id)) |> Core.Repo.one()
  end

  test "get_version" do
    fixture = Fixture.cog_string_valid()
    {:ok, cs} = fixture |> ConfigService.create()
    {:ok, version} = ConfigService.get_version(fixture |> Map.fetch!(:name))
    assert version == cs.version
  end

  test "get version not found in redis" do
    fixture = Fixture.cog_string_valid()
    {:ok, cs} = fixture |> ConfigService.create()
    Core.Redis.command(:flushall)

    with_mock Core.Redis, [:passthrough], [] do
      {:ok, version} = ConfigService.get_version(fixture |> Map.fetch!(:name))
      assert version == cs.version

      commands = [
        ["SET", "cog:val:#{cs.namespace}.#{cs.name}", cs.value],
        ["SET", "cog:ver:#{cs.namespace}.#{cs.name}", cs.version]
      ]

      assert_called(Core.Redis.transaction_pipeline(commands))
    end
  end

  test "get_value" do
    fixture = Fixture.cog_string_valid()
    {:ok, cs} = fixture |> ConfigService.create()
    {:ok, version} = ConfigService.get_value(fixture |> Map.fetch!(:name))
    assert version == cs.value
  end

  test "get value not found in redis" do
    fixture = Fixture.cog_string_valid()
    {:ok, cs} = fixture |> ConfigService.create()
    Core.Redis.command(:flushall)

    with_mock Core.Redis, [:passthrough], [] do
      {:ok, version} = ConfigService.get_value(fixture |> Map.fetch!(:name))
      assert version == cs.value

      commands = [
        ["SET", "cog:val:#{cs.namespace}.#{cs.name}", cs.value],
        ["SET", "cog:ver:#{cs.namespace}.#{cs.name}", cs.version]
      ]

      assert_called(Core.Redis.transaction_pipeline(commands))
    end
  end

  describe "with collection" do
    setup do
      {:ok, col_cs} =
        Fixture.col_valid()
        |> Core.CollectionService.create()

      {:ok, cs} = Fixture.cog_string_valid() |> ConfigService.create()
      {:ok, col_cs: col_cs, cog_cs: cs}
    end

    test "it should promote new version of collection", %{col_cs: col_cs, cog_cs: cog_cs} do
      {:ok, col} = Core.CollectionService.add_config(col_cs, [cog_cs])
      assert col.version > col_cs.version
    end

    @tag focus: true
    test "it should prmote another new version when the config get updated", %{
      col_cs: col_cs,
      cog_cs: cog_cs
    } do
      {:ok, col_v1} = Core.CollectionService.add_config(col_cs, [cog_cs])

      Fixture.cog_string_valid()
      |> Map.put(:value, "x@y.com")
      |> ConfigService.create()

      col_v2 = Core.CollectionService.find(col_cs.name, col_cs.namespace)

      assert col_cs.version < col_v1.version
      assert col_v1.version < col_v2.version
    end
  end

  describe "search" do
    setup do
      fixture = Fixture.cog_string_valid()
      {:ok, cs} = fixture |> ConfigService.create()
      {:ok, cs: cs, fixture: fixture}
    end

    test "search through name", %{cs: cs} do
      result = %{keyword: cs.name} |> ConfigService.search()
      assert Enum.any?(result, fn i -> i.id == cs.id end)
    end

    test "search specific field", %{cs: cs} do
      result = %{name: cs.name} |> ConfigService.search()
      assert Enum.any?(result, fn i -> i.id == cs.id end)

      result = %{name: cs.name, namespace: cs.namespace} |> ConfigService.search()
      assert Enum.any?(result, fn i -> i.id == cs.id end)

      result = %{name: cs.name, namespace: "non_exist_namespace"} |> ConfigService.search()
      assert length(result) == 0
    end

    test "when passed unknown attribute won't fail", %{cs: cs} do
      result = %{attribute_that_uknown: cs.name} |> ConfigService.search()
      assert length(result) == 0
    end
  end

  describe "check the diff" do
    test "not updating when the json being resorted" do
      fixture_obj = Fixture.cog_object_valid()

      new_value = """
      {
        "attr_number" : 1,
        "name" : "credit_card"
      }

      """

      fixture_obj = fixture_obj |> Map.put(:value, new_value)
      fixture_obj |> ConfigService.create()

      assert 1 ==
               Repo.one(
                 from(p in Model.Config, select: count(p.id), where: p.name == ^fixture_obj[:name])
               )

      new_value = """
      {
        "name" : "credit_card",
        "attr_number" : 1
      }

      """

      fixture_obj = fixture_obj |> Map.put(:value, new_value)
      {:ok, _} = fixture_obj |> ConfigService.create()

      assert 1 ==
               Repo.one(
                 from(p in Model.Config, select: count(p.id), where: p.name == ^fixture_obj[:name])
               )
    end

    test "when the value is not a json string" do
      {:ok, schema_cs} = Fixture.schema_generic_number_above_100() |> SchemaService.create()

      {:ok, _} =
        ConfigService.create(%{
          name: "number_100",
          value: 100,
          namespace: "default",
          schema: schema_cs.name
        })

      {:ok, _} =
        ConfigService.create(%{
          name: "number_100",
          value: 100,
          namespace: "default",
          schema: schema_cs.name
        })

      assert 1 ==
               Repo.one(
                 from(p in Model.Config, select: count(p.id), where: p.name == "number_100")
               )
    end
  end
end
