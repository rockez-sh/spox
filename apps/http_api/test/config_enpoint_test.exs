defmodule HttpApi.ConfigEnpointTest do
  use ExUnit.Case, async: true
  use Core.DataCase
  use Plug.Test
  import HttpApi.TestUtils
  alias Core.Fixture
  alias Core.ConfigService
  import Mock

  test "post /api/cog" do
    fixture = Fixture.cog_string_valid
    {status, cog_json } = make_call(:post, "/api/cog", %{cog: fixture})
    assert status == 200
    created_cog = ConfigService.find(fixture |> Map.fetch!(:name))
    assert cog_json == created_cog |> Core.ConfigService.as_json |> Poison.encode!
  end

  test "post /api/cog schema validation" do
    Fixture.schema_object |> Core.SchemaService.create
    {status, response } = make_call(:post, "/api/cog", %{cog: Fixture.cog_object_json_schema_invalid})
    assert status == 400
    %{"success" => false , "schema_errors" => [schema_error | _]} = response |> Poison.decode!
    assert schema_error == %{"message" => "Type mismatch. Expected Integer but got String.", "path" => "#/attr_number"}
  end

  test "post /api/cog schema not found" do
    {status, response } = make_call(:post, "/api/cog", %{cog: Fixture.cog_object_json_schema_invalid})
    assert status == 400
    %{"success" => false , "errors" => %{"schema" => schema_not_found} } = response |> Poison.decode!
    assert schema_not_found == "not found"
  end

  test "post /api/cog/:namespace/:name" do
    {:ok, expected_result} = Fixture.cog_string_valid |> ConfigService.create
    with_mock ConfigService, [:passthrough], [] do
      {_status, json} = make_call(:get, "/api/cog/#{expected_result.namespace}/#{expected_result.name}", %{})
      assert_called ConfigService.find(expected_result.name, expected_result.namespace)
      assert json == %{data: expected_result |> ConfigService.as_json} |> Poison.encode!
    end
  end
end