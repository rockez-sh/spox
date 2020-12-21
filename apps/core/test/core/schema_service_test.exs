defmodule Core.SchemaServiceTest do
  use ExUnit.Case, async: false
  alias Core.Fixture
  import Core.SchemaService
  use Core.DataCase

  test "should create schema" do
    fxtr = Fixture.schema_object()
    {:ok, cs} = fxtr |> create
    assert cs.id != nil
    assert cs.name == fxtr |> Map.fetch!(:name)
    assert cs.value == fxtr |> Map.fetch!(:value)
  end

  describe "search" do
    setup do
      fixture = Fixture.schema_object()
      {:ok, cs} = fixture |> create
      {:ok, cs: cs, fixture: fixture}
    end

    test "search through name", %{cs: cs} do
      result = %{keyword: cs.name} |> search
      assert Enum.any?(result, fn i -> i.id == cs.id end)
    end

    test "search specific field", %{cs: cs} do
      result = %{name: cs.name} |> search
      assert Enum.any?(result, fn i -> i.id == cs.id end)

      result = %{name: "non_exist_namespace"} |> search
      assert length(result) == 0
    end

    test "when passed unknown attribute won't fail", %{cs: cs} do
      result = %{attribute_that_uknown: cs.name} |> search
      assert length(result) == 0
    end
  end
end
