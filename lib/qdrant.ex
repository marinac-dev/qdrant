defmodule Qdrant do
  @moduledoc """
  Documentation for Qdrant.
  """

  use Qdrant.Api.Wrapper

  @doc """

  Creates a collection with the given name and body.
  Body must be a map with the key `vectors`, example:

  ```elixir
  %{
    vectors: %{
      size: 42,
      distance: "Cosine"
    }
  }
  ```

  For full documentation check: [Qdrant Create Collection](https://qdrant.github.io/qdrant/redoc/index.html#tag/collections/operation/create_collection)
  """
  def create_collection(collection_name, body, timeout \\ nil) do
    api_call("Collections", :create_collection, [collection_name, body, timeout])
  end

  @doc """
  Deletes a collection with the given name.
  """
  def delete_collection(collection_name, timeout \\ nil) do
    api_call("Collections", :delete_collection, [collection_name, timeout])
  end

  @doc """
  Returns a list of all collections.
  """
  def list_collections() do
    api_call("Collections", :list_collections, [])
  end

  @doc """
  Returns information about a collection with the given name.
  """
  def collection_info(collection_name) do
    api_call("Collections", :collection_info, [collection_name])
  end

  @doc """
  Perform insert + updates on points. If point with given ID already exists - it will be overwritten.

  Body must be a map with the key `points` or `batch`, example:

  ```elixir
  %{
    points: [
      %{
        id: 1,
        vector: vector1
      },
      %{
        id: 2,
        vector: vector2
      }
    ]
  }
  ```

  Or batch:

  ```elixir
  %{
    batch: %{
      ids: [1, 2],
      vectors: [vector1, vector2]
    }
  }
  ```

  For full documentation check: [Qdrant Upsert Points](https://qdrant.github.io/qdrant/redoc/index.html#tag/points/operation/upsert_points)
  """
  def upsert_point(collection_name, body, wait \\ false, ordering \\ nil) do
    api_call("Points", :upsert_points, [collection_name, body, wait, ordering])
  end
end
