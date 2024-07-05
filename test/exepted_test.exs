defmodule ExeptedTest do
  use ExUnit.Case
  doctest Exepted

  test "greets the world" do
    assert Exepted.hello() == :world
  end
end
