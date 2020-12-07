defmodule HttpApi.SchemaEndpointTest do
  use ExUnit.Case, async: true
  use Core.DataCase
  use Plug.Test
  import HttpApi.TestUtils
  alias Core.Fixture
  alias Core.SchemaService, as: SchemaSVC

  test "post /api/sch" do
    fixture = Fixture.schema_object
    {status, sch_json } = make_call(:post, "/api/sch", %{sch: fixture})
    assert status == 200
    created_sch = SchemaSVC.find(fixture |> Map.fetch!(:name))
    assert sch_json == created_sch |> SchemaSVC.as_json |> Poison.encode!
  end

end