defmodule HttpApi.SearchEndpointTest do
  use ExUnit.Case, async: true
  use Core.DataCase
  use Plug.Test
  import HttpApi.TestUtils
  alias Core.CollectionService

  describe "using term" do
    setup do
      {:ok, params: %{keyword: "daily"}}
    end
    test "search Collection name & desc", %{params: params} do
      {:ok, cs} = %{name: "user_daily_report_receiver", namespace: "default",
      desc: "user daily report receiver"} |> CollectionService.create
      {status, response} =  make_call(:post, "/api/search", params)
      assert status == 200
      %{"data" => %{"collections"=> [col|_] }} = response |> Poison.decode!
      assert col["id"] == cs.id
    end
  end

  describe "using field filter" do
  end
end