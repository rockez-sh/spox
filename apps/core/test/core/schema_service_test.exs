defmodule Core.SchemaServiceTest do
  use ExUnit.Case, async: false
  alias Core.Fixture
  import Core.SchemaService
  use Core.DataCase

  test "should create schema" do
    fxtr = Fixture.schema_object
    {:ok, cs} = fxtr |> create
    assert cs.id != nil
    assert cs.name == fxtr |> Map.fetch!(:name)
    assert cs.value == fxtr |> Map.fetch!(:value)
  end
end