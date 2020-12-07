defmodule HttpApi.ConfigEnpointTest do
  use ExUnit.Case, async: true
  use Core.DataCase
  use Plug.Test
  import HttpApi.TestUtils
  alias Core.Fixture
  import Mock
  import Ecto.Query

  test "post /api/cog" do
    fixture = Fixture.cog_string_valid
    {status, cog_json } = make_call(:post, "/api/cog", %{cog: fixture})
    assert status == 200
    created_cog = Core.Model.Config |> first |> Core.Repo.one
    assert cog_json == created_cog |> Core.Config.as_json |> Poison.encode!
  end
end