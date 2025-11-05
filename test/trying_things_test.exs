defmodule TryingThingsTest do
  use ExUnit.Case
  doctest TryingThings

  test "greets the world" do
    assert TryingThings.hello() == :world
  end
end
