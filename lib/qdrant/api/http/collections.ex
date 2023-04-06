defmodule Qdrant.Api.Http.Collections do
  @moduledoc """
  Qdrant API Collections.

  Collections are searchable collections of points.
  """

  use Qdrant.Api.Http.Client

  @doc false
  scope "/collections"

  # TODO: Rewrite typespecs to have primary types and complex types
  # TODO: Fix typespecs for some functions
  @type extended_point_id :: list(integer() | String.t())
  @type vector_params :: %{size: integer(), distance: String.t()}

  # * Update aliases of the collections
  @type delete_alias :: %{alias_name: String.t()}
  @type create_alias :: %{alias_name: String.t(), collection_name: String.t()}
  @type rename_alias :: %{old_alias_name: String.t(), new_alias_name: String.t()}
  @type alias_actions_list :: %{actions: [delete_alias | create_alias | rename_alias]}

  # * Create index for the collection field
  @type ordering :: :weak | :medium | :strong
  @type index_body_type :: :keyword | :integer | :float | :geo | :text
  @type tokenizer_type :: :prefix | :whitespace | :word
  @type field_schema :: %{
          type: index_body_type,
          tokenizers: tokenizer_type,
          min_token_len: integer(),
          max_token_len: integer(),
          lowercase: boolean()
        }

  @type body_schema :: %{field_name: String.t(), field_schema: field_schema}

  # * Update collection cluster setup
  @type shadred_operation_params :: %{shard_id: integer(), from_peer_id: integer(), to_peer_id: integer()}
  @type drop_replica_params :: %{shard_id: integer(), peer_id: integer()}
  @type cluster_update_body ::
          %{move_shard: shadred_operation_params}
          | %{replicate_shard: shadred_operation_params}
          | %{abort_transfer: shadred_operation_params}
          | %{drop_replica: drop_replica_params}

  # * Points
  @type vector :: list(float()) | %{name: String.t(), vector: list(float())}
  @type vectors :: list(vector())
  @type points_batch :: %{batch: %{ids: list(integer() | String.t()), vectors: vectors(), payloads: list(map())}}

  @type point :: %{id: integer() | String.t(), vector: vector(), payload: map()}
  @type points_list :: list(point())
  @type upsert_body :: points_batch() | points_list()

  @type delete_body :: list(integer() | String.t())

  @type field_condition :: %{
          key: String.t(),
          match: %{value: String.t()} | %{text: String.t()} | %{any: String.t()},
          range: %{gte: float(), lte: float(), gt: float(), lt: float()},
          geo_bounding_box: %{
            top_left: %{lat: float(), lon: float()},
            bottom_right: %{lat: float(), lon: float()}
          },
          geo_radius: %{
            center: %{lat: float(), lon: float()},
            radius: float()
          },
          values_count: %{
            lt: integer(),
            lte: integer(),
            gt: integer(),
            gte: integer()
          }
        }

  @type filter_type :: list(field_condition()) | %{is_empty: map()} | %{has_id: extended_point_id()}
  @type search_params :: %{
          hnsw_ef: integer() | nil,
          exact: boolean(),
          quantization: %{ignore: boolean() | false, rescore: boolean() | false} | nil
        }
  @type search_body :: %{
          vector: vector(),
          filter: %{must: filter_type(), should: filter_type(), must_not: filter_type()} | nil,
          params: search_params(),
          limit: integer()
        }

  @type set_payload_body :: %{payload: map(), points: extended_point_id(), filter: filter_type()}
  @type delete_payload_body :: %{keys: list(String.t()), points: extended_point_id(), filter: filter_type()}

  @type consistency :: non_neg_integer() | :majority | :quorum | :all
  @type with_payload_interface :: boolean() | list(String.t()) | %{include: String.t(), exclude: String.t()}
  @type scroll_body :: %{
          offset: non_neg_integer() | String.t(),
          limit: non_neg_integer(),
          filter: filter_type(),
          with_payload: with_payload_interface(),
          with_vector: boolean() | list(String.t())
        }

  @type search_request :: %{
          vector: vector(),
          filter: filter_type(),
          params: search_params(),
          limit: non_neg_integer(),
          offset: non_neg_integer(),
          with_payload: with_payload_interface(),
          with_vector: boolean() | list(String.t()),
          score_threshold: integer() | nil
        }
  @type search_batch_body :: list(search_request())
  @type recommend_body :: %{
          positive: extended_point_id(),
          negative: extended_point_id(),
          filter: filter_type(),
          params: search_params(),
          limit: non_neg_integer(),
          offset: non_neg_integer(),
          with_payload: with_payload_interface(),
          with_vector: boolean() | list(String.t()),
          score_threshold: non_neg_integer() | nil,
          using: String.t(),
          lookup_from: %{collection: String.t(), vector: String.t()} | nil
        }
  @type recommend_batch_body :: list(recommend_body())

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

  - collection_name **required**: name of the collection

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

  ## Request sample (json)

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
  # TODO: add type for body
  @spec create_collection(String.t(), map(), integer() | nil) :: {:ok, map()} | {:error, any()}
  def create_collection(name, body, timeout \\ nil) do
    path = "/#{name}" <> timeout_query(timeout)
    put(path, body)
  end

  @doc """
  Update collection parameters [See more on qdrant](https://qdrant.github.io/qdrant/redoc/index.html#tag/collections/operation/update_collection)

  ## Path parameters

  - collection_name **required** : Name of the collection to update

  ## Query parameters

  - timeout *optional* : Wait for operation commit timeout in seconds. If timeout is reached - request will return with service error.

  ## Request body schema

  - `optimizers_config` *optional*: Custom params for Optimizers. If none - values from service configuration file are used. This operation is blocking, it will only proceed ones all current optimizations are complete

  - `params` *optional*: Collection base params. If none - values from service configuration file are used.

  ## Request sample (json)

  ```json
  {
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
    "params": {
      "replication_factor": 1,
      "write_consistency_factor": 1
    }
  }
  ```
  """
  # TODO: add type for body
  @spec update_collection(String.t(), map(), integer() | nil) :: {:ok, map()} | {:error, any()}
  def update_collection(collection_name, body, timeout \\ nil) do
    path = "/#{collection_name}" <> timeout_query(timeout)
    patch(path, body)
  end

  @doc """
  Drop collection and all associated data [See more on qdrant](https://qdrant.github.io/qdrant/redoc/index.html#tag/collections/operation/delete_collection)

  ## Path parameters

  - collection_name **required** : Name of the collection to delete

  ## Query parameters

  - timeout *optional* : Wait for operation commit timeout in seconds. If timeout is reached - request will return with service error.
  """
  @spec delete_collection(String.t(), integer() | nil) :: {:ok, map()} | {:error, any()}
  def delete_collection(collection_name, timeout \\ nil) do
    path = "/#{collection_name}" <> timeout_query(timeout)
    delete(path)
  end

  @doc """
  Update aliases of the collections [See more on qdrant](https://qdrant.github.io/qdrant/redoc/index.html#tag/collections/operation/update_aliases)

  ## Query parameters

  - timeout *optional* : Wait for operation commit timeout in seconds. If timeout is reached - request will return with service error.

  ## Request body schema

  - `actions` *required*: List of actions to perform. Create_alias or delete_alias or rename_alias.


  ## Example

      iex> Qdrant.update_aliases(%{
      ...>   actions: [
      ...>     %{create_alias: %{alias: "alias_name", collection: "collection_name"}},
      ...>     %{delete_alias: %{alias: "alias_name"}},
      ...>     %{rename_alias: %{alias: "alias_name", new_alias: "new_alias_name"}}
      ...>   ]
      ...> })
      {:ok, %{"result" => true, "status" => "ok", "time" => 0}}

  """
  @spec update_aliases(alias_actions_list(), integer() | nil) :: {:ok, map()} | {:error, any()}
  def update_aliases(body, timeout \\ nil) do
    path = "/aliases" <> timeout_query(timeout)
    post(path, body)
  end

  @doc """
  Create index for field in collection [See more on qdrant](https://qdrant.github.io/qdrant/redoc/index.html#tag/collections/operation/create_field_index)

  ## Path parameters

  - collection_name **required** : Name of the collection

  ## Query parameters

  - `wait` *optional* : If true, wait for changes to actually happen

  - `ordering` *optional* : Define ordering guarantees for the operation

  ## Request body schema

  - `field_name` *required* : Name of the field to index

  - `field_schema` *required* : Type of the field to index

  ## Example

      iex> Qdrant.create_field_index("collection_name", %{field_name: "field_name", field_schema: "field_schema"})
      {:ok, %{"status" => "ok", "time" => 0, "result" => %{"operation_id" => 42, status: "acknowledged"} }}}}
  """
  @spec create_field_index(String.t(), body_schema(), boolean(), ordering() | nil) :: {:ok, map()} | {:error, any()}
  def create_field_index(collection_name, %{field_name: _} = body, wait \\ false, ordering \\ nil) do
    path =
      "/#{collection_name}/index?"
      |> add_query_param("wait", wait)
      |> add_query_param("ordering", ordering)

    put(path, body)
  end

  @doc """
  Delete index for field in collection [See more on qdrant](https://qdrant.github.io/qdrant/redoc/index.html#tag/collections/operation/delete_field_index)

  ## Path parameters

  - collection_name **required** : Name of the collection

  - field_name **required** : Name of the field where to delete the index

  ## Query parameters

  - `wait` *optional* : If true, wait for changes to actually happen

  - `ordering` *optional* : Define ordering guarantees for the operation

  ## Example

      iex> Qdrant.delete_field_index("collection_name", "field_name")
      {:ok, %{"status" => "ok", "time" => 0, "result" => %{"operation_id" => 42, status: "acknowledged"} }}}}
  """

  @spec delete_field_index(String.t(), String.t(), boolean(), ordering() | nil) :: {:ok, map()} | {:error, any()}
  def delete_field_index(collection_name, field_name, wait \\ false, ordering \\ nil) do
    path =
      "/#{collection_name}/index/#{field_name}?"
      |> add_query_param("wait", wait)
      |> add_query_param("ordering", ordering)

    delete(path)
  end

  @doc """
  Get cluster information for a collection [See more on qdrant](https://qdrant.github.io/qdrant/redoc/index.html#tag/collections/operation/collection_cluster_info)

  ## Path parameters

  - collection_name **required** : Name of the collection to retrieve the cluster info for

  ## Example

      iex> Qdrant.collection_cluster_info("collection_name")
      {:ok, %{"status" => "ok", "time" => 0, "result" => %{"operation_id" => 42, status: "acknowledged"} }}}}
  """
  @spec collection_cluster_info(String.t()) :: {:ok, map()} | {:error, any()}
  def collection_cluster_info(collection_name) do
    path = "/#{collection_name}/cluster"
    get(path)
  end

  @doc """
  Update collection cluster setup [See more on qdrant](https://qdrant.github.io/qdrant/redoc/index.html#tag/collections/operation/update_collection_cluster)

  ## Path parameters

  - collection_name **required** : Name of the collection on which to to apply the cluster update operation

  ## Query parameters

  - `timeout` *optional* : Wait for operation commit timeout in seconds. If timeout is reached - request will return with service error.

  ## Request body schema

  - `move_shard` or `replicate_shard` or `abort_transfer` or `drop_replica` **required** : List of actions to perform.

  ## Example

      iex> Qdrant.update_collection_cluster("collection_name", %{
      ...>   move_shard: %{
      ...>     shard_id: 1,
      ...>     to_peer_id: 42,
      ...>     from_peer_id: 69
      ...>   }
      ...> })
      {:ok, %{"status" => "ok", "time" => 0, "result" => %{"operation_id" => 42, status: "acknowledged"} }}}}

      iex> Qdrant.update_collection_cluster("collection_name", %{
      ...>   drop_replica: %{
      ...>     shard_id: 1,
      ...>     peer_id: 42
      ...>   }
      ...> })
      {:ok, %{"status" => "ok", "time" => 0, "result" => %{"operation_id" => 42, status: "acknowledged"} }}}}
  """
  @spec update_collection_cluster(String.t(), cluster_update_body(), integer() | nil) :: {:ok, map()} | {:error, any()}
  def update_collection_cluster(collection_name, body, timeout \\ nil) do
    path = "/#{collection_name}/cluster" <> timeout_query(timeout)
    post(path, body)
  end

  @doc """
  Get list of all aliases for a collection [See more on qdrant](https://qdrant.github.io/qdrant/redoc/index.html#tag/collections/operation/get_collection_aliases)

  ## Path parameters

  - collection_name **required** : Name of the collection to retrieve the aliases for

  ## Example

      iex> Qdrant.get_collection_aliases("collection_name")
      {:ok, %{"status" => "ok", "time" => 0, "result" => %{"operation_id" => 42, status: "acknowledged"} }}}}
  """
  @spec get_collection_aliases(String.t()) :: {:ok, map()} | {:error, any()}
  def get_collection_aliases(collection_name) do
    path = "/#{collection_name}/aliases"
    get(path)
  end

  # # # # # # #
  # * Points  #
  # # # # # # #

  @doc """
  Perform insert + updates on points. If point with given ID already exists - it will be overwritten. [See more on qdrant](https://qdrant.github.io/qdrant/redoc/index.html#tag/points/operation/upsert_points)

  ## Path parameters

  - collection_name **required** : Name of the collection to update from

  ## Query parameters

  - `wait` *optional* : If true, wait for changes to actually happen

  - `ordering` *optional* : Define ordering guarantees for the operation

  ## Request body schema

  - `batch` **required** : List of points to insert or update
  OR
  - `points` **required** : Point to insert or update
  """
  @spec upsert_points(String.t(), upsert_body(), boolean() | nil, ordering() | nil) :: {:ok, map()} | {:error, any()}
  def upsert_points(collection_name, body, wait \\ false, ordering \\ nil) do
    path =
      "/#{collection_name}/points?"
      |> add_query_param("wait", wait)
      |> add_query_param("ordering", ordering)

    post(path, body)
  end

  @doc """
  Delete points

  ## Path parameters

  - collection_name **required** : Name of the collection to update from

  ## Query parameters

  - `wait` *optional* : If true, wait for changes to actually happen

  - `ordering` *optional* : Define ordering guarantees for the operation

  ## Request body schema

  - `points` **required** : List of points to delete
  """
  @spec delete_points(String.t(), delete_body(), boolean() | nil, ordering() | nil) :: {:ok, map()} | {:error, any()}
  def delete_points(collection_name, body, wait \\ false, ordering \\ nil) do
    path =
      "/#{collection_name}/points/delete?"
      |> add_query_param("wait", wait)
      |> add_query_param("ordering", ordering)

    delete(path, body)
  end

  @doc """
  Set payload values for points

  ## Path parameters

  - collection_name **required** : Name of the collection to set from

  ## Query parameters

  - `wait` *optional* : If true, wait for changes to actually happen

  - `ordering` *optional* : Define ordering guarantees for the operation

  ## Request body schema

  - `payload` **required** : Payload to set

  - `points` **required** : Assigns payload to each point in this list

  - `filter` *optional* : Assigns payload to each point that satisfy this filter condition
  """
  @spec set_payload(String.t(), set_payload_body(), boolean() | nil, ordering() | nil) :: {:ok, map()} | {:error, any()}
  def set_payload(collection_name, body, wait \\ false, ordering \\ nil) do
    path =
      "/#{collection_name}/points/payload?"
      |> add_query_param("wait", wait)
      |> add_query_param("ordering", ordering)

    post(path, body)
  end

  @doc """
  Replace full payload of points with new one

  ## Path parameters

  - collection_name **required** : Name of the collection to set from

  ## Query parameters

  - `wait` *optional* : If true, wait for changes to actually happen

  - `ordering` *optional* : Define ordering guarantees for the operation

  ## Request body schema

  - `payload` **required** : Payload to set

  - `points` **required** : Assigns payload to each point in this list

  - `filter` *optional* : Assigns payload to each point that satisfy this filter condition
  """
  @spec overwrite_payload(String.t(), set_payload_body(), boolean() | nil, ordering() | nil) ::
          {:ok, map()} | {:error, any()}
  def overwrite_payload(collection_name, body, wait \\ false, ordering \\ nil) do
    path =
      "/#{collection_name}/points/payload?"
      |> add_query_param("wait", wait)
      |> add_query_param("ordering", ordering)

    put(path, body)
  end

  @doc """
  Delete specified key payload for points

  ## Path parameters

  - collection_name **required** : Name of the collection to delete from

  ## Query parameters

  - `wait` *optional* : If true, wait for changes to actually happen

  - `ordering` *optional* : Define ordering guarantees for the operation

  ## Request body schema

  - `keys` **required** : List of payload keys to remove from payload

  - `points` **required** : Deletes values from each point in this list

  - `filter` *optional* : Deletes values from points that satisfy this filter condition
  """
  @spec delete_payload(String.t(), delete_payload_body(), boolean() | nil, ordering() | nil) ::
          {:ok, map()} | {:error, any()}
  def delete_payload(collection_name, body, wait \\ false, ordering \\ nil) do
    path =
      "/#{collection_name}/points/payload/delete?"
      |> add_query_param("wait", wait)
      |> add_query_param("ordering", ordering)

    post(path, body)
  end

  @doc """
  Remove all payload for specified points

  ## Path parameters

  - collection_name **required** : Name of the collection to clear payload from

  ## Query parameters

  - `wait` *optional* : If true, wait for changes to actually happen

  - `ordering` *optional* : Define ordering guarantees for the operation

  ## Request body schema

  - `points` **required** : List of points to clear payload from
  """
  @spec clear_payload(String.t(), list(integer() | String.t()), boolean() | nil, ordering() | nil) ::
          {:ok, map()} | {:error, any()}
  def clear_payload(collection_name, body, wait \\ false, ordering \\ nil) do
    path =
      "/#{collection_name}/points/payload/clear?"
      |> add_query_param("wait", wait)
      |> add_query_param("ordering", ordering)

    post(path, body)
  end

  @doc """
  Scroll request - paginate over all points which matches given filtering condition

  ## Path parameters

  - collection_name **required** : Name of the collection to retrieve from

  ## Query parameters

  - `consistency` *optional* : Define read consistency guarantees for the operation

  ## Request body schema

  - `offset` *optional* : Start ID to read points from.

  - `limit` *optional* : Page size. Default: 10

  - `filter` *optional* : Look only for points which satisfies this conditions. If not provided - all points.

  - `with_payload` *optional* : Select which payload to return with the response. Default: All

  - `with_vector` *optional* : Options for specifying which vector to include
  """
  @spec scroll_points(String.t(), scroll_body(), consistency() | nil) :: {:ok, map()} | {:error, any()}
  def scroll_points(collection_name, body, consistency \\ nil) do
    path =
      "/#{collection_name}/points/scroll?"
      |> add_query_param("consistency", consistency)

    post(path, body)
  end

  @doc """
  Retrieve closest points based on vector similarity and given filtering conditions

  ## Path parameters

  - collection_name **required** : Name of the collection to search in

  ## Query parameters

  - `consistency` *optional* : Define read consistency guarantees for the operation

  ## Request body schema

  - `vector` **required** : Vector to search for

  - `filter` *optional* : Filter to apply to the search results. Look only for points which satisfies this conditions

  - `params` *optional* : Additional search parameters

  - `limit` **required** : Maximum number of points to return

  - `offset` *optional* : Offset of the first result to return. May be used to paginate results. Note: large offset values may cause performance issues.

  - `with_payload` *optional* : Select which payload to return with the response. Default: None

  - `with_vector` *optional* : Whether to return the point vector with the result?

  - `score_threshold` *optional* : Define a minimal score threshold for the result. If defined, less similar results will not be returned. Score of the returned result might be higher or smaller than the threshold depending on the Distance function used. E.g. for cosine similarity only higher scores will be returned.
  """

  @spec search_points(String.t(), search_body(), integer() | nil) :: {:ok, map()} | {:error, any()}
  def search_points(collection_name, body, consistency \\ nil) do
    path =
      "/#{collection_name}/points/search"
      |> add_query_param("consistency", consistency)

    post(path, body)
  end

  @doc """
  Retrieve by batch the closest points based on vector similarity and given filtering conditions

  ## Path parameters

  - collection_name **required** : Name of the collection to search in

  ## Query parameters

  - `consistency` *optional* : Define read consistency guarantees for the operation

  ## Request body schema

  - `searches` **required** : List of searches to perform
  """
  @spec search_points_batch(String.t(), search_batch_body(), consistency() | nil) :: {:ok, map()} | {:error, any()}
  def search_points_batch(collection_name, body, consistency \\ nil) do
    path =
      "/#{collection_name}/points/search/batch"
      |> add_query_param("consistency", consistency)

    post(path, body)
  end

  @doc """
  Look for the points which are closer to stored positive examples and at the same time further to negative examples.

  ## Path parameters

  - collection_name **required** : Name of the collection to search in

  ## Query parameters

  - `consistency` *optional* : Define read consistency guarantees for the operation

  ## Request body schema

  - `positive` **required** : Look for vectors closest to those

  - `negative` **required** : Look for vectors further from those | Try to avoid vectors like this

  - `filter` *optional* : Look only for points which satisfies this conditions

  - `params` *optional* : Additional search parameters

  - `limit` **required** : Maximum number of points to return

  - `offset` *optional* : Offset of the first result to return. May be used to paginate results. Note: large offset values may cause performance issues.

  - `with_payload` *optional* : Select which payload to return with the response. Default: None

  - `with_vector` *optional* : Whether to return the point vector with the result?

  - `score_threshold` *optional* : Define a minimal score threshold for the result. If defined, less similar results will not be returned. Score of the returned result might be higher or smaller than the threshold depending on the Distance function used. E.g. for cosine similarity only higher scores will be returned.

  - `using` *optional* : Define which vector to use for recommendation, if not specified - try to use default vector

  - `lookup_from` *optional* : The location used to lookup vectors. If not specified - use current collection. Note: the other collection should have the same vector size as the current collection
  """
  @spec recommend_points(String.t(), recommend_body(), consistency() | nil) :: {:ok, map()} | {:error, any()}
  def recommend_points(collection_name, body, consistency \\ nil) do
    path =
      "/#{collection_name}/points/recommend"
      |> add_query_param("consistency", consistency)

    post(path, body)
  end

  @doc """
  Request points based on positive and negative examples.

  ## Path parameters

  - collection_name **required** : Name of the collection to search in

  ## Query parameters

  - `consistency` *optional* : Define read consistency guarantees for the operation

  ## Request body schema

  - `searches` **required** : List of searches to perform
  """
  @spec recommend_points_batch(String.t(), recommend_batch_body(), consistency() | nil) ::
          {:ok, map()} | {:error, any()}
  def recommend_points_batch(collection_name, body, consistency \\ nil) do
    path =
      "/#{collection_name}/points/recommend/batch"
      |> add_query_param("consistency", consistency)

    post(path, body)
  end

  @doc """
  Count points which matches given filtering condition

  ## Path parameters

  - collection_name **required** : Name of the collection to count in

  ## Request body schema

  - `filter` *optional* : Filter to apply to the search results. Look only for points which satisfies this conditions

  - `exact` *optional* : If true, count exact number of points. If false, count approximate number of points faster. Approximate count might be unreliable during the indexing process. Default: true
  """
  @spec count_points(String.t(), %{filter: filter_type(), exact: boolean()}) :: {:ok, map()} | {:error, any()}
  def count_points(collection_name, body) do
    path = "/#{collection_name}/points/count"
    post(path, body)
  end

  # * Private helpers
  defp timeout_query(timeout), do: if(timeout, do: "?timeout=#{timeout}", else: "")
  defp add_query_param(path, _, nil), do: path
  defp add_query_param(path, key, value), do: path <> "&#{key}=#{value}"
end
