defmodule Core.UtilsTest do
  use ExUnit.Case, async: false
  import  Core.Utils

  test "chain multi" do
    assert {:ok, %{say_helo: "1"}} == multi() |> run(:say_helo, fn(_)-> {:ok, "1"} end )

    assert {:error, :second_step, "cannot continue" } == multi()
    |> run(:say_helo, fn(_)-> {:ok, "1"} end )
    |> run(:second_step, fn(_)-> {:error, "cannot continue"} end )
    |> run(:third_step, fn(_)-> {:ok, "final"} end )

    assert {:error, :second_step, "cannot continue" } == multi()
    |> run(:say_helo, fn(_)-> {:ok, "1"} end )
    |> run(:second_step, fn(_)-> {:error, "cannot continue"} end )
    |> run(:third_step, fn(_)-> {:error, "final"} end )

    assert {:error, :third_step, "error on final" } == multi()
    |> run(:say_helo, fn(_)-> {:ok, "1"} end )
    |> run(:second_step, fn(_)-> {:ok, "continue"} end )
    |> run(:third_step, fn(_)-> {:error, "error on final"} end )
  end
end