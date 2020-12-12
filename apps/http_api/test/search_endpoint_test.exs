defmodule HttpApi.SearchEndpointTest do
  use ExUnit.Case
  use Core.DataCase
  use Plug.Test
  import HttpApi.TestUtils
  alias Core.Fixture
  alias Core.CollectionService
  alias Core.SchemaService
  alias Core.ConfigService

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
    setup do
      {:ok, col} = Fixture.col_valid |> CollectionService.create
      {:ok, sch} = Fixture.schema_object |> SchemaService.create
      {:ok, cog} = Fixture.cog_string_valid |> ConfigService.create
      { :ok, %{col: col, sch: sch, cog: cog }}
    end

    test "find by namespace", %{cog: cog, col: col} do
      params = %{namespace: "default"}
      {status, json} = make_call(:post, "/api/search", params)
      assert status == 200
      %{"data" => %{
        "schemas" => resp_schemas,
        "collections"=> [resp_col|_],
        "configs" => [resp_cog|_]}} = json |> Poison.decode!
      assert length(resp_schemas) == 0
      assert resp_col["id"] == col.id
      assert resp_cog["id"] == cog.id
    end

    test "find combine filter and keyword", %{cog: cog} do
      params = %{namespace: "default", keyword: "email"}
      {status, json} = make_call(:post, "/api/search", params)
      assert status == 200
      %{"data" => %{
        "schemas" => resp_schema,
        "collections" => resp_cols,
        "configs" => [resp_cog|_]}} = json |> Poison.decode!
      assert length(resp_cols) == 0
      assert length(resp_schema) == 0
      assert resp_cog["id"] == cog.id
    end
  end
end