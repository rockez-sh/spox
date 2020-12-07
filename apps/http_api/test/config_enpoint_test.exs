defmodule HttpApi.ConfigEnpointTest do
  use ExUnit.Case, async: true
  use Core.DataCase
  use Plug.Test
  import HttpApi.TestUtils
  alias Core.Fixture
  import Mock
  import Ecto.Query
  alias Core.Config , as: ConfigSVC

  test "post /api/cog" do
    fixture = Fixture.cog_string_valid
    {status, cog_json } = make_call(:post, "/api/cog", %{cog: fixture})
    assert status == 200
    created_cog = ConfigSVC.find(fixture |> Map.fetch!(:name))
    assert cog_json == created_cog |> Core.Config.as_json |> Poison.encode!
  end
end