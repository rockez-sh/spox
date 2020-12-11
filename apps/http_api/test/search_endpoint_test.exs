defmodule HttpApi.SearchEndpointTest do
  use ExUnit.Case, async: true
  use Core.DataCase
  use Plug.Test
  import HttpApi.TestUtils
  alias Core.Fixture
  alias Core.SchemaService
  alias Core.CollectionService
  alias Core.ConfigService

  describe "using term" do
    setup do
      {:ok, params: %{keyword: "daily"}}
    end
    @tag focus: true
    test "search Collection name & desc", %{params: params} do
      {:ok, cs} = %{name: "user_daily_report_receiver", namespace: "default",
      desc: "user daily report receiver"} |> CollectionService.create
      {status, response} =  make_call(:post, "/api/search", params)
      expected_response = %{
        data: %{
          collections: [CollectionService.as_json(cs)]
        }
      } |> Poison.encode!
      assert status == 200
      assert response == expected_response
    end
  end

  describe "using field filter" do
  end
end