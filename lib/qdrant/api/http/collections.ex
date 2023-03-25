defmodule Qdrant.Api.Http.Collections do
  @moduledoc """
  Qdrant API Collections.

  Collections are searchable collections of points.
  """

  use Qdrant.Api.Http.Client

  url "/collections"

  @doc """
  Get list name of all existing collections.

  ## Example
      iex> Qdrant.Api.Http.Collections.list_collections()
      {:ok, %Tesla.Env{status: 200,
        body: %{
            "result" => %{"collections" => [...]},
            "status" => "ok",
            "time" => 2.043e-6
          }
        }
      }
  """
  @spec list_collections() :: {:ok, Tesla.Env.t()} | {:error, any()}
  def list_collections() do
    get("")
  end

  @doc """
  Get detailed information about specified existing collection

  ## Path parameters

  - collection_name (required) : name of the collection

  ## Example
      iex> Qdrant.Api.Http.Collections.collection_info("my_collection")
      {:ok, %Tesla.Env{status: 200,
        body: %{
            "result" => %{
              "collection_type" => "Flat",
              "name" => "my_collection",
              "points_count" => 0,
              "vectors_count" => 0
            },
            "status" => "ok",
            "time" => 2.043e-6
          }
        }
      }
  """
  @spec collection_info(String.t()) :: {:ok, map()} | {:error, any()}
  def collection_info(collection_name) do
    get("/#{collection_name}")
  end

end
