defmodule TcpApiTest do
  use ExUnit.Case
  doctest TcpApi

  test "greets the world" do
    assert TcpApi.hello() == :world
  end
end
