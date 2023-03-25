defmodule QdrantTest do
  use ExUnit.Case
  doctest Qdrant

  test "greets the world" do
    assert Qdrant.hello() == :world
  end
end
