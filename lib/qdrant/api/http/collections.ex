defmodule Qdrant.Api.Http.Collections do
  @moduledoc """
  Qdrant API Collections.

  Collections are searchable collections of points.
  """

  use Qdrant.Api.Http.Client

  @doc false
  scope("/collections")

  @doc """
  Get list name of all existing collections. [See more on qdrant](https://qdrant.github.io/qdrant/redoc/index.html#tag/collections/operation/get_collection)

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
  Get detailed information about specified existing collection. [See more on qdrant](https://qdrant.github.io/qdrant/redoc/index.html#tag/collections/operation/get_collection)

  ## Path parameters

  - collection_name **required** : name of the collection

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

  @doc """
  Create new collection with given parameters. [See more on qdrant](https://qdrant.github.io/qdrant/redoc/index.html#tag/collections/operation/create_collection)

  ## Path parameters

  - name **required** : Name of the new collection

  ## Query parameters

  - timeout *optional* : Wait for operation commit timeout in seconds. If timeout is reached - request will return with service error.

  ## Request body schema

  - `vectors` **required**: Vector params separator for single and multiple vector modes. Single mode: `%{size: 128, distance: "Cosine"}` or multiple mode: `%{default: {size: 128, distance: "Cosine"}}`

  - `shard_number` *optional*: `null` or `positive integer` Default: `null`. \n Number of shards in collection. Default is 1 for standalone, otherwise equal to the number of nodes Minimum is 1.

  - `replication_factor` *optional*: 	`null` or `positive integer` Default: `null`. \n Number of shards replicas. Default is 1 Minimum is 1

  - `write_consistency_factor` *optional*: `null` or `positive integer` Default: `null`. \n Defines how many replicas should apply the operation for us to consider it successful. Increasing this number will make the collection more resilient to inconsistencies, but will also make it fail if not enough replicas are available. Does not have any performance impact.

  - `on_disk_payload` *optional*: `boolean or null` Default: `null`. \n If true - point's payload will not be stored in memory. It will be read from the disk every time it is requested. This setting saves RAM by (slightly) increasing the response time. Note: those payload values that are involved in filtering and are indexed - remain in RAM.

  - `hnsw_config` *optional*: Custom params for HNSW index. If none - values from service configuration file are used.

  - `wal_config` *optional*: Custom params for WAL. If none - values from service configuration file are used.

  - `optimizers_config` *optional*: Custom params for Optimizers. If none - values from service configuration file are used.

  - `init_from` *optional*: `null` or `string` Default: `null`. \n  Specify other collection to copy data from.

  - `quantization_config` *optional*: Default: `null`. \m Quantization parameters. If none - quantization is disabled.
  ## Request sample

  ```json
  {
    "vectors": {
      "size": 1,
      "distance": "Cosine"
    },
    "shard_number": null,
    "replication_factor": null,
    "write_consistency_factor": null,
    "on_disk_payload": null,
    "hnsw_config": {
      "m": 0,
      "ef_construct": 0,
      "full_scan_threshold": 0,
      "max_indexing_threads": null,
      "on_disk": null,
      "payload_m": null
    },
    "wal_config": {
      "wal_capacity_mb": 0,
      "wal_segments_ahead": 0
    },
    "optimizers_config": {
      "deleted_threshold": 0,
      "vacuum_min_vector_number": 0,
      "default_segment_number": 0,
      "max_segment_size": 0,
      "memmap_threshold": 0,
      "indexing_threshold": 0,
      "flush_interval_sec": 0,
      "max_optimization_threads": 0
    },
    "init_from": null,
    "quantization_config": null
  }
  ```

  """
  @spec create_collection(String.t(), map()) :: {:ok, map()} | {:error, any()}
  def create_collection(name, body) do
    put("/#{name}", body)
  end

  @spec create_collection(String.t(), map(), integer()) :: {:error, any} | {:ok, Tesla.Env.t()}
  def create_collection(name, body, timeout) do
    put("/#{name}?timeout=#{timeout}", body)
  end
end
