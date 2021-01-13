defmodule HttpApi.CollectionEnpointTest do
  use ExUnit.Case, async: true
  use Core.DataCase
  use Plug.Test
  import HttpApi.TestUtils
  alias Core.Fixture
  alias Core.CollectionService
  alias Core.ConfigService
  alias Core.Redis
  import Mock

  setup do
    {:ok, fixture: Fixture.col_valid()}
  end

  test "post /api/col", %{fixture: fixture} do
    {status, col_json} = make_call(:post, "/api/col", %{col: fixture})
    assert status == 200
    created_col = CollectionService.find(fixture[:name], fixture[:namespace])
    assert col_json == created_col |> CollectionService.as_json() |> Poison.encode!()
  end

  describe "without desc" do
    test "post /api/col 400", %{fixture: fixture} do
      {status, col_json} = make_call(:post, "/api/col", %{col: fixture |> Map.delete(:desc)})
      assert status == 400
      assert CollectionService.find(fixture[:name], fixture[:namespace]) == nil

      assert col_json ==
               """
               {"success":false,"errors":{"desc":"can't be blank"}}
               """
               |> String.trim()
    end
  end

  test "get /api/col/:namespace/:name" do
    {:ok, expected_result} = Fixture.col_valid() |> CollectionService.create()

    with_mock CollectionService, [:passthrough], [] do
      {_status, json} =
        make_call(:get, "/api/col/#{expected_result.namespace}/#{expected_result.name}", %{})

      assert_called(CollectionService.find(expected_result.name, expected_result.namespace))
      assert json == %{data: expected_result |> CollectionService.as_json()} |> Poison.encode!()
    end
  end

  test "post /api/col/:namespace/:name/add" do
    Redis.command(["FLUSHALL"])
    {:ok, col} = Fixture.col_valid() |> CollectionService.create()

    {:ok, cog} =
      Fixture.cog_string_valid()
      |> ConfigService.create()

    {200, json} =
      make_call(:post, "/api/col/#{col.namespace}/#{col.name}/add", %{configs: [cog.name]})

    %{"data" => %{"configs" => [cog_json | _]}} = json |> Poison.decode!()

    assert cog_json |> Map.fetch!("name") == cog.name
    assert cog_json |> Map.fetch!("value") == cog.value
  end

  test "post /api/col/:namespace/:name/add and config not present" do
    Redis.command(["FLUSHALL"])
    {:ok, col} = Fixture.col_valid() |> CollectionService.create()

    {400, json} =
      make_call(:post, "/api/col/#{col.namespace}/#{col.name}/add", %{configs: ["xconfigx"]})

    assert %{"success" => false, "message" => "Cannot find config with name(s) xconfigx "} ==
             json |> Poison.decode!()
  end
end
