defmodule Qdrant.Api.Http.Cluster do
  @moduledoc """
  Service distributed setup and cluster management.
  """

  alias Qdrant.Api.Http.Client

  defp client, do: Client.client()

  @type shard_params :: %{
          shard_id: non_neg_integer(),
          to_peer_id: non_neg_integer(),
          from_peer_id: non_neg_integer()
        }

  @type move_shard :: %{move_shard: shard_params()}
  @type replicate_shard :: %{replicate_shard: shard_params()}
  @type abort_transfer :: %{abort_transfer: shard_params()}
  @type drop_replica :: %{
          shard_id: non_neg_integer(),
          peer_id: non_neg_integer()
        }

  @type shard_operations :: move_shard() | replicate_shard() | abort_transfer() | drop_replica()

  @doc """
  Create shard key for a collection.

  ## Parameters

  * `collection_name` **required** - Name of the collection to create shards for
  * `body` **required** - Shard key configuration
  * `timeout` - Optional timeout in seconds for operation commit

  ## Example

      iex> body = %{shard_key: "city"}
      iex> Qdrant.Api.Http.Cluster.create_shard_key("my_collection", body)
      {:ok, %{"result" => true, "status" => "ok"}}

  """
  @spec create_shard_key(String.t(), map(), integer() | nil) :: {:ok, map()} | {:error, any()}
  def create_shard_key(collection_name, body, timeout \\ nil) do
    path =
      "/collections/#{collection_name}/shards"
      |> Client.add_query_param("timeout", timeout)

    client()
    |> Tesla.put(path, body)
    |> parse_response()
  end

  @doc """
  Delete shard key for a collection.

  ## Parameters

  * `collection_name` **required** - Name of the collection
  * `body` **required** - Shard key to delete
  * `timeout` - Optional timeout in seconds for operation commit

  ## Example

      iex> body = %{shard_key: "city"}
      iex> Qdrant.Api.Http.Cluster.delete_shard_key("my_collection", body)
      {:ok, %{"result" => true, "status" => "ok"}}

  """
  @spec delete_shard_key(String.t(), map(), integer() | nil) :: {:ok, map()} | {:error, any()}
  def delete_shard_key(collection_name, body, timeout \\ nil) do
    path =
      "/collections/#{collection_name}/shards/delete"
      |> Client.add_query_param("timeout", timeout)

    client()
    |> Tesla.post(path, body)
    |> parse_response()
  end

  @doc """
  Get information about the current state and composition of the cluster.

  [See more on qdrant](https://qdrant.github.io/qdrant/redoc/index.html#tag/cluster/operation/cluster_status)

  ## Example

      iex> Qdrant.Api.Http.Cluster.cluster_status()
      {:ok, %{"result" => %{"status" => "disabled"}, "status" => "ok", "time" => 0}}

  """
  @spec cluster_status() :: {:ok, map()} | {:error, any()}
  def cluster_status do
    client()
    |> Tesla.get("/cluster")
    |> parse_response()
  end

  @doc """
  Tries to recover current peer Raft state.

  [See more on qdrant](https://qdrant.github.io/qdrant/redoc/index.html#tag/cluster/operation/recover_current_peer)

  ## Example

      iex> Qdrant.Api.Http.Cluster.recover_current_peer()
      {:ok, %{"result" => true, "status" => "ok", "time" => 0}}

  """
  @spec recover_current_peer() :: {:ok, map()} | {:error, any()}
  def recover_current_peer do
    client()
    |> Tesla.post("/cluster/recover", %{})
    |> parse_response()
  end

  @doc """
  Remove peer from the cluster by its id.

  Tries to remove peer from the cluster. Will return an error if peer has shards on it.

  [See more on qdrant](https://qdrant.github.io/qdrant/redoc/index.html#tag/cluster/operation/remove_peer)

  ## Parameters

  * `peer_id` **required** - Peer id

  ## Example

      iex> Qdrant.Api.Http.Cluster.remove_peer(42)
      {:ok, %{"result" => true, "status" => "ok", "time" => 0}}

  """
  @spec remove_peer(integer() | String.t()) :: {:ok, map()} | {:error, any()}
  def remove_peer(peer_id) do
    client()
    |> Tesla.delete("/cluster/peer/#{peer_id}")
    |> parse_response()
  end

  @doc """
  Get cluster information for a collection.

  [See more on qdrant](https://qdrant.github.io/qdrant/redoc/index.html#tag/cluster/operation/collection_cluster_info)

  ## Parameters

  * `collection_name` **required** - Collection name

  ## Example

      iex> Qdrant.Api.Http.Cluster.collection_cluster_info("my_collection")
      {:ok, %{"result" => %{...}, "status" => "ok"}}

  """
  @spec collection_cluster_info(String.t()) :: {:ok, map()} | {:error, any()}
  def collection_cluster_info(collection_name) do
    client()
    |> Tesla.get("/collections/#{collection_name}/cluster")
    |> parse_response()
  end

  @doc """
  Update collection cluster setup.

  [See more on qdrant](https://qdrant.github.io/qdrant/redoc/index.html#tag/cluster/operation/update_collection_cluster)

  ## Parameters

  * `collection_name` **required** - Collection name
  * `body` **required** - Cluster operations (move_shard, replicate_shard, abort_transfer, or drop_replica)
  * `timeout` - Optional timeout in seconds for operation commit

  ## Example

      iex> body = %{move_shard: %{shard_id: 1, to_peer_id: 2, from_peer_id: 1}}
      iex> Qdrant.Api.Http.Cluster.update_collection_cluster("my_collection", body)
      {:ok, %{"result" => true, "status" => "ok"}}

  """
  @spec update_collection_cluster(String.t(), shard_operations(), integer() | nil) ::
          {:ok, map()} | {:error, any()}
  def update_collection_cluster(collection_name, body, timeout \\ nil) do
    path =
      "/collections/#{collection_name}/cluster"
      |> Client.add_query_param("timeout", timeout)

    client()
    |> Tesla.post(path, body)
    |> parse_response()
  end

  # Private helpers
  defp parse_response({:ok, %Tesla.Env{status: 200, body: body}}) do
    {:ok, body}
  end

  defp parse_response({:error, reason}) do
    {:error, reason}
  end

  defp parse_response({:ok, %Tesla.Env{} = env}) do
    {:error, %{status: env.status, body: env.body}}
  end
end
