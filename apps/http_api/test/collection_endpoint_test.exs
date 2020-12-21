defmodule HttpApi.CollectionEnpointTest do
  use ExUnit.Case, async: true
  use Core.DataCase
  use Plug.Test
  import HttpApi.TestUtils
  alias Core.Fixture
  alias Core.CollectionService
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
end
