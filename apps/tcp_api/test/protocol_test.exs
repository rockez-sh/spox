defmodule TcpApi.ProtocolTest do
  use ExUnit.Case, async: true
  use Core.DataCase
  alias Core.Fixture
  alias Core.ConfigService
  import  TcpApi.Protocol

  test "cog:ver" do
    fixture = Fixture.cog_string_valid()
    {:ok, cs} = fixture |> ConfigService.create
    version = "0 #{cs.version}"
    assert {:reply, version} == process("ver:cog:" <> Map.fetch!(fixture, :namespace) <> "." <> Map.fetch!(fixture, :name))
  end

  test "cog:val" do
    fixture = Fixture.cog_string_valid()
    {:ok, cs} = fixture |> ConfigService.create
    value = "0 " <> cs.value
    assert {:reply, value} == process("val:cog:" <> Map.fetch!(fixture, :namespace) <> "." <> Map.fetch!(fixture, :name))
  end
end