defmodule QdrantTest do
  use ExUnit.Case, async: true

  doctest Qdrant.Client
  doctest Qdrant.Api.Http.Request
end
