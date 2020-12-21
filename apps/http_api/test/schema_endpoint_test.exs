defmodule HttpApi.SchemaEndpointTest do
  use ExUnit.Case
  use Core.DataCase
  use Plug.Test
  import HttpApi.TestUtils
  alias Core.Fixture
  alias Core.SchemaService
  import Ecto.Query
  import Mock

  test "post /api/sch" do
    fixture = Fixture.schema_object()
    {status, sch_json} = make_call(:post, "/api/sch", %{sch: fixture})
    assert status == 200
    created_sch = SchemaService.find(fixture |> Map.fetch!(:name))
    assert sch_json == created_sch |> SchemaService.as_json() |> Poison.encode!()
  end

  test "post /api/sch upserting" do
    fixture = Fixture.schema_object()
    {status, _} = make_call(:post, "/api/sch", %{sch: fixture})
    assert status == 200

    new_schema = """
      {
        "type" : "object",
        "properties" : {
          "name" : {"type" : "string"},
          "attr_number" : {"type": "integer", "enum" : [1,2,3]}
        }
      }
    """

    {status, _} = make_call(:post, "/api/sch", %{sch: fixture |> Map.put(:value, new_schema)})
    assert status == 200

    schema_name = fixture |> Map.fetch!(:name)

    assert 1 ==
             Core.Model.Schema
             |> where([s], s.name == ^schema_name)
             |> select([s], count(s.id))
             |> Core.Repo.one()
  end

  test "post /api/sch parse json" do
    fixture = Fixture.schema_object()

    new_schema = """
      {
        "type" : "object"
        "properties" : {
          "name" : {"type" : "string"},
          "attr_number" : {"type": "integer", "enum" : [1,2,3]}
        }
      }
    """

    {status, sch_json} =
      make_call(:post, "/api/sch", %{sch: fixture |> Map.put(:value, new_schema)})

    assert status == 400
    %{"success" => false, "errors" => %{"value" => value_error}} = sch_json |> Poison.decode!()
    assert value_error == "Invalid JSON"
  end

  test "post /api/sch resolve schema" do
    fixture = Fixture.schema_object()

    new_schema = """
      {
        "type" : "xobjectx",
        "properties" : {
          "name" : {"type" : "string"},
          "attr_number" : {"type": "integer", "enum" : [1,2,3]}
        }
      }
    """

    {status, sch_json} =
      make_call(:post, "/api/sch", %{sch: fixture |> Map.put(:value, new_schema)})

    assert status == 400
    %{"success" => false, "errors" => %{"value" => value_error}} = sch_json |> Poison.decode!()
    assert value_error == "Invalid JSON Schema"
  end

  describe "get /api/sch/:name " do
    test "should find schema" do
      {:ok, expected_result} = Fixture.schema_object() |> SchemaService.create()

      with_mock SchemaService, [:passthrough], [] do
        {_status, json} = make_call(:get, "/api/sch/#{expected_result.name}", %{})
        assert_called(SchemaService.find(expected_result.name))
        assert json == %{data: expected_result |> SchemaService.as_json()} |> Poison.encode!()
      end
    end
  end
end
