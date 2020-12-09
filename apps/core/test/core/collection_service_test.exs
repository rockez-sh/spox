defmodule Core.CollectionServiceTest do
  use ExUnit.Case, async: false
  alias Core.Fixture
  import Core.CollectionService
  use Core.DataCase

  test "should create collection" do
    fxtr = Fixture.col_valid
    {:ok, cs} = fxtr |> create
    assert cs.id != nil
    assert cs.name == fxtr |> Map.fetch!(:name)
    assert cs.desc == fxtr |> Map.fetch!(:desc)
    assert cs.version == 0
  end

  test "should upserting" do
    fxtr = Fixture.col_valid
    {:ok, cs} = fxtr |> create
    {:ok, cs2} = fxtr |> Map.put(:desc, "New Desc") |> create
    assert cs.id == cs2.id
    assert cs.version == cs2.version
    assert cs.desc != cs2.desc
  end

  test "different namespace different record" do
    fxtr = Fixture.col_valid
    {:ok, cs} = fxtr |> create
    {:ok, cs2} = fxtr |> Map.put(:namespace, "group_b") |> create

    assert cs.id != cs2.id
  end
end