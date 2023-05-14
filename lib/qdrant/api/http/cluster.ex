defmodule Qdrant.Api.Http.Cluster do
  @moduledoc """
  Service distributed setup.
  """

  use Qdrant.Api.Http.Client

  @doc false
  scope "/cluster"

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
  Get information about the current state and composition of the cluster. [See more on qdrant](https://qdrant.github.io/qdrant/redoc/index.html#tag/cluster/operation/cluster_status)

  ## Example

      iex> Qdrant.Api.Http.Cluster.cluster_status()
      {:ok, %Tesla.Env{status: 200,
        body: %{
            "result" => %{
              "status" => "disabled",
            },
            "status" => "ok",
            "time" => 0
          }
        }
      }

  """
  @spec cluster_status() :: {:ok, Tesla.Env.t()} | {:error, any()}
  def cluster_status() do
    get("")
  end

  @doc """
  Tries to recover current peer Raft state. [See more on qdrant](https://qdrant.github.io/qdrant/redoc/index.html#tag/cluster/operation/recover_current_peer

  ## Example

      iex> Qdrant.Api.Http.Cluster.recover_current_peer()
      {:ok, %Tesla.Env{status: 200,
        body: %{
            "result" => true,
            "status" => "ok",
            "time" => 0
          }
        }
      }

  """
  @spec recover_current_peer() :: {:ok, Tesla.Env.t()} | {:error, any()}
  def recover_current_peer() do
    post("/recover", %{})
  end

  @doc """
  Remove peer from the cluster by its id. [See more on qdrant](https://qdrant.github.io/qdrant/redoc/index.html#tag/cluster/operation/remove_peer)
  Tries to remove peer from the cluster. Will return an error if peer has shards on it.

  ## Parameters

    * `peer_id` **required** - `integer` peer id

  ## Example

      iex> Qdrant.Api.Http.Cluster.remove_peer(42)
      {:ok, %Tesla.Env{status: 200,
        body: %{
            "result" => true,
            "status" => "ok",
            "time" => 0
          }
        }
      }
  """
  @spec remove_peer(String.t()) :: {:ok, Tesla.Env.t()} | {:error, any()}
  def remove_peer(peer_id) do
    delete("/peer/#{peer_id}")
  end

  @doc """
  Get cluster information for a collection. [See more on qdrant](https://qdrant.github.io/qdrant/redoc/index.html#tag/cluster/operation/collection_cluster_info)

  ## Parameters

    * `collection_name` **required** - `string` collection name

  """
  @spec collection_cluster_info(String.t()) :: {:ok, Tesla.Env.t()} | {:error, any()}
  def collection_cluster_info(collection_name) do
    get("/collection/#{collection_name}/cluster")
  end

  @doc """
  Update collection cluster setup. [See more on qdrant](https://qdrant.github.io/qdrant/redoc/index.html#tag/cluster/operation/update_collection_cluster)

  ## Parameters

    * `collection_name` **required** - `string` collection name

  ## Query Parameters

  - `timeout` - Wait for operation commit timeout in seconds. If timeout is reached - request will return with service error.
  """
  @spec update_collection_cluster(String.t(), shard_operations()) :: {:ok, Tesla.Env.t()} | {:error, any()}
  def update_collection_cluster(collection_name, body) do
    post("/collection/#{collection_name}/cluster", body)
  end
end
