defmodule HttpApi.ConfigEnpointTest do
  use ExUnit.Case, async: true
  use Plug.Test
  import HttpApi.TestUtils
  alias Core.Fixture

  test "post /api/cog" do
    assert {200, "OK"} == make_call(:post, "/api/cog", %{cog: Fixture.cog_string_valid})
  end
end