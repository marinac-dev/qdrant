defmodule Qdrant.Api.Http.Cluster do
  @moduledoc """
  Service distributed setup and cluster management.

  Functions accepting a `Qdrant.Client` are the primary API. No-client forms
  remain available for compatibility with application and environment configuration.
  """

  alias Qdrant.Api.Http.Request
  alias Qdrant.{Client, Config, Types}

  @doc """
  Create a shard key for a collection.

  Options:

  * `:timeout` - operation commit timeout in seconds

  ## Example

      client = Qdrant.Client.new!(url: "http://localhost:6333")
      body = %{shard_key: "city"}
      Qdrant.Api.Http.Cluster.create_shard_key(client, "my_collection", body)
  """
  @spec create_shard_key(Client.t(), String.t(), Types.request_body()) :: Types.result()
  @spec create_shard_key(Client.t(), String.t(), Types.request_body(), Types.request_options()) :: Types.result()
  @spec create_shard_key(String.t(), Types.request_body()) :: Types.result()
  @spec create_shard_key(String.t(), Types.request_body(), integer() | nil) :: Types.result()
  def create_shard_key(collection_name, body),
    do: with_compat_client(&create_shard_key(&1, collection_name, body))

  def create_shard_key(%Client{} = client, collection_name, body),
    do: create_shard_key(client, collection_name, body, [])

  def create_shard_key(collection_name, body, timeout),
    do: with_compat_client(&create_shard_key(&1, collection_name, body, timeout: timeout))

  def create_shard_key(%Client{} = client, collection_name, body, opts) do
    path = "/collections/#{Request.segment(collection_name)}/shards"
    Request.request(client, :put, path, query: [timeout: Keyword.get(opts, :timeout)], body: body)
  end

  @doc """
  Delete a shard key for a collection.

  Options:

  * `:timeout` - operation commit timeout in seconds

  ## Example

      client = Qdrant.Client.new!(url: "http://localhost:6333")
      body = %{shard_key: "city"}
      Qdrant.Api.Http.Cluster.delete_shard_key(client, "my_collection", body)
  """
  @spec delete_shard_key(Client.t(), String.t(), Types.request_body()) :: Types.result()
  @spec delete_shard_key(Client.t(), String.t(), Types.request_body(), Types.request_options()) :: Types.result()
  @spec delete_shard_key(String.t(), Types.request_body()) :: Types.result()
  @spec delete_shard_key(String.t(), Types.request_body(), integer() | nil) :: Types.result()
  def delete_shard_key(collection_name, body),
    do: with_compat_client(&delete_shard_key(&1, collection_name, body))

  def delete_shard_key(%Client{} = client, collection_name, body),
    do: delete_shard_key(client, collection_name, body, [])

  def delete_shard_key(collection_name, body, timeout),
    do: with_compat_client(&delete_shard_key(&1, collection_name, body, timeout: timeout))

  def delete_shard_key(%Client{} = client, collection_name, body, opts) do
    path = "/collections/#{Request.segment(collection_name)}/shards/delete"
    Request.request(client, :post, path, query: [timeout: Keyword.get(opts, :timeout)], body: body)
  end

  @doc """
  Get information about the current state and composition of the cluster.

  ## Example

      client = Qdrant.Client.new!(url: "http://localhost:6333")
      Qdrant.Api.Http.Cluster.cluster_status(client)
  """
  @spec cluster_status(Client.t()) :: Types.result()
  @spec cluster_status() :: Types.result()
  def cluster_status, do: with_compat_client(&cluster_status/1)
  def cluster_status(%Client{} = client), do: Request.request(client, :get, "/cluster")

  @doc """
  Tries to recover the current peer Raft state.

  ## Example

      client = Qdrant.Client.new!(url: "http://localhost:6333")
      Qdrant.Api.Http.Cluster.recover_current_peer(client)
  """
  @spec recover_current_peer(Client.t()) :: Types.result()
  @spec recover_current_peer() :: Types.result()
  def recover_current_peer, do: with_compat_client(&recover_current_peer/1)

  def recover_current_peer(%Client{} = client),
    do: Request.request(client, :post, "/cluster/recover", body: %{})

  @doc """
  Remove a peer from the cluster by its id.

  Options:

  * `:force` - remove the peer even when it has shards or replicas

  ## Example

      client = Qdrant.Client.new!(url: "http://localhost:6333")
      Qdrant.Api.Http.Cluster.remove_peer(client, 42, force: true)
  """
  @spec remove_peer(Client.t(), Types.extended_point_id()) :: Types.result()
  @spec remove_peer(Client.t(), Types.extended_point_id(), Types.request_options()) :: Types.result()
  @spec remove_peer(Types.extended_point_id()) :: Types.result()
  @spec remove_peer(Types.extended_point_id(), boolean() | nil) :: Types.result()
  def remove_peer(peer_id), do: with_compat_client(&remove_peer(&1, peer_id))
  def remove_peer(%Client{} = client, peer_id), do: remove_peer(client, peer_id, [])

  def remove_peer(peer_id, force),
    do: with_compat_client(&remove_peer(&1, peer_id, force: force))

  def remove_peer(%Client{} = client, peer_id, opts) do
    path = "/cluster/peer/#{Request.segment(peer_id)}"
    Request.request(client, :delete, path, query: [force: Keyword.get(opts, :force)])
  end

  @doc """
  Get cluster information for a collection.

  ## Example

      client = Qdrant.Client.new!(url: "http://localhost:6333")
      Qdrant.Api.Http.Cluster.collection_cluster_info(client, "my_collection")
  """
  @spec collection_cluster_info(Client.t(), String.t()) :: Types.result()
  @spec collection_cluster_info(String.t()) :: Types.result()
  def collection_cluster_info(collection_name),
    do: with_compat_client(&collection_cluster_info(&1, collection_name))

  def collection_cluster_info(%Client{} = client, collection_name) do
    path = "/collections/#{Request.segment(collection_name)}/cluster"
    Request.request(client, :get, path)
  end

  @doc """
  Update collection cluster setup.

  Options:

  * `:timeout` - operation commit timeout in seconds

  ## Example

      client = Qdrant.Client.new!(url: "http://localhost:6333")
      body = %{move_shard: %{shard_id: 1, to_peer_id: 2, from_peer_id: 1}}
      Qdrant.Api.Http.Cluster.update_collection_cluster(client, "my_collection", body)
  """
  @spec update_collection_cluster(Client.t(), String.t(), Types.request_body()) :: Types.result()
  @spec update_collection_cluster(
          Client.t(),
          String.t(),
          Types.request_body(),
          Types.request_options()
        ) :: Types.result()
  @spec update_collection_cluster(String.t(), Types.request_body()) :: Types.result()
  @spec update_collection_cluster(String.t(), Types.request_body(), integer() | nil) :: Types.result()
  def update_collection_cluster(collection_name, body),
    do: with_compat_client(&update_collection_cluster(&1, collection_name, body))

  def update_collection_cluster(%Client{} = client, collection_name, body),
    do: update_collection_cluster(client, collection_name, body, [])

  def update_collection_cluster(collection_name, body, timeout),
    do: with_compat_client(&update_collection_cluster(&1, collection_name, body, timeout: timeout))

  def update_collection_cluster(%Client{} = client, collection_name, body, opts) do
    path = "/collections/#{Request.segment(collection_name)}/cluster"
    Request.request(client, :post, path, query: [timeout: Keyword.get(opts, :timeout)], body: body)
  end

  defp with_compat_client(callback) do
    with {:ok, opts} <- Config.client_options(),
         {:ok, client} <- Client.new(default_insecure_api_key_option(opts)) do
      callback.(client)
    end
  end

  defp default_insecure_api_key_option(opts) do
    if is_nil(opts[:allow_insecure_api_key]),
      do: Keyword.put(opts, :allow_insecure_api_key, false),
      else: opts
  end
end
