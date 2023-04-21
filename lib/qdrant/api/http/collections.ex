defmodule Qdrant.Api.Http.Collections do
  @moduledoc """
  Qdrant API Collections.

  Collections are searchable collections of points.
  """

  use Qdrant.Utils.Types
  use Qdrant.Api.Http.Client

  @doc false
  scope "/collections"

  # TODO: Fix typespecs for some functions

  # * Update aliases of the collections
  @type delete_alias :: %{alias_name: String.t()}
  @type create_alias :: %{alias_name: String.t(), collection_name: String.t()}
  @type rename_alias :: %{old_alias_name: String.t(), new_alias_name: String.t()}
  @type alias_actions_list :: %{actions: [delete_alias | create_alias | rename_alias]}

  # * Create index for the collection field
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

      iex> Qdrant.list_collection_aliases("collection_name")
      {:ok, %{"status" => "ok", "time" => 0, "result" => %{"operation_id" => 42, status: "acknowledged"} }}}}
  """
  @spec list_collection_aliases(String.t()) :: {:ok, map()} | {:error, any()}
  def list_collection_aliases(collection_name) do
    path = "/#{collection_name}/aliases"
    get(path)
  end

  # # # # # # ## # # # # # #
  # *       Points       * #
  # # # # # # ## # # # # # #

  # * Private helpers
  defp timeout_query(timeout), do: if(timeout, do: "?timeout=#{timeout}", else: "")
  defp add_query_param(path, _, nil), do: path
  defp add_query_param(path, key, value), do: path <> "&#{key}=#{value}"
end
