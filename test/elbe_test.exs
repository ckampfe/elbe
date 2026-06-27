defmodule ElbeTest do
  use ExUnit.Case
  doctest Elbe

  test "greets the world" do
    assert Elbe.hello() == :world
  end
end
