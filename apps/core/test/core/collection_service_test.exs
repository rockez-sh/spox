defmodule Core.CollectionServiceTest do
  use ExUnit.Case, async: false
  alias Core.Fixture
  alias Core.Model
  alias Core.Repo
  alias Core.Redis
  import Mock
  import Core.CollectionService
  use Core.DataCase


  test "should create collection" do
    fxtr = Fixture.col_valid
    {:ok, cs} = fxtr |> create
    assert cs.id != nil
    assert cs.name == fxtr |> Map.fetch!(:name)
    assert cs.desc == fxtr |> Map.fetch!(:desc)
    assert cs.version == 0
  end

  test "should upserting" do
    fxtr = Fixture.col_valid
    {:ok, cs} = fxtr |> create
    {:ok, cs2} = fxtr |> Map.put(:desc, "New Desc") |> create
    assert cs.id == cs2.id
    assert cs.version == cs2.version
    assert cs.desc != cs2.desc
  end

  test "different namespace different record" do
    fxtr = Fixture.col_valid
    {:ok, cs} = fxtr |> create
    {:ok, cs2} = fxtr |> Map.put(:namespace, "group_b") |> create

    assert cs.id != cs2.id
  end

  describe "touching" do
    setup do
      {:ok, col} = Fixture.col_valid |> Map.put(:version, 0) |> create
      {:ok, cog} = %Model.Config{}
        |> Model.Config.changeset(Fixture.cog_string_valid |> Map.put(:version, 0) |> Map.put(:latest, true))
        |> Repo.insert
      {:ok, col: col, cog: cog}
    end
    test "promoting version", %{col: col, cog: cog} do
      {:ok, ncol } = touch(Repo, col, cog)
      assert ncol.version > col.version
    end

    test "make copy to redis", %{col: col, cog: cog} do
      with_mock Redis, [:passthrough], []  do
        {:ok, ncol } = touch(Repo, col, cog)
        commands = [
          ["SET", "col:ver:#{col.namespace}.#{col.name}", ncol.version],
          ["HSET", "col:val:#{col.namespace}.#{col.name}", cog.name, cog.value]
        ]
        assert_called Redis.transaction_pipeline(commands)
      end
    end
  end

  describe "get_version" do
    setup do
      {:ok, col} = Fixture.col_valid |> Map.put(:version, 0) |> create
      {:ok, cog} = %Model.Config{}
        |> Model.Config.changeset(Fixture.cog_string_valid |> Map.put(:version, 0) |> Map.put(:latest, true) |> Map.put(:collection_id, col.id))
        |> Repo.insert
      {:ok, col} = touch(Repo, col, cog)
      {:ok, col: col, cog: cog}
    end

    test 'should get version from redis',%{col: col} do
      with_mock Redis, [:passthrough], []  do
        {:ok, version} = get_version(col.name, col.namespace)
        assert version == col.version
        assert_called Redis.command(:get, "col:ver:#{col.namespace}.#{col.name}")
      end
    end

    test 'when copy not present in redis', %{col: col, cog: cog} do
      Redis.command(["FLUSHALL"])
      with_mock Redis, [:passthrough], []  do
        {:ok, version} = get_version(col.name, col.namespace)
        assert version == col.version
        commands = [
          ["SET", "col:ver:#{col.namespace}.#{col.name}", col.version],
          ["HSET", "col:val:#{col.namespace}.#{col.name}", cog.name, cog.value]
        ]
        assert_called Redis.transaction_pipeline(commands)
      end
    end
  end
  describe "search" do
    setup do
      fixture = Fixture.col_valid
      {:ok, cs} = fixture |> Map.put(:desc, "some description that are worth to read") |> create
      {:ok, cs: cs,fixture: fixture}
    end

    test "search through name & desc", %{cs: cs} do
      result = cs.name |> search
      assert Enum.any?(result, fn(i) -> i.id == cs.id end)

      result = "worth" |> search
      assert Enum.any?(result, fn(i) -> i.id == cs.id end)
    end

    test "search specific field", %{cs: cs} do
      result = %{name: cs.name} |> search
      assert Enum.any?(result, fn(i) -> i.id == cs.id end)

      result = %{name: cs.name, namespace: "non_exist_namespace"} |> search
      assert length(result) == 0
    end

    test "when passed unknown attribute won't fail", %{cs: cs} do
      result = %{attribute_that_uknown: cs.name} |> search
      assert length(result) == 0
    end
  end
end