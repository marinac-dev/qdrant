defmodule Qdrant.Api.Http.Snapshots do
  @moduledoc """
  Qdrant API Snapshots operations.

  Snapshots allow to backup and restore collection data.
  """

  alias Qdrant.Api.Http.Client

  defp client, do: Client.client()

  # Collection snapshots

  @doc """
  List snapshots for a collection.

  ## Parameters

  * `collection_name` **required** - Name of the collection

  ## Example

      iex> Qdrant.Api.Http.Snapshots.list_snapshots("my_collection")
      {:ok, %{"result" => %{"name" => "snapshot.snapshot", ...}}}

  """
  @spec list_snapshots(String.t()) :: {:ok, map()} | {:error, any()}
  def list_snapshots(collection_name) do
    client()
    |> Tesla.get("/collections/#{collection_name}/snapshots")
    |> parse_response()
  end

  @doc """
  Create a snapshot for a collection.

  ## Parameters

  * `collection_name` **required** - Name of the collection
  * `wait` - Optional boolean, if true, wait for changes to actually happen

  ## Example

      iex> Qdrant.Api.Http.Snapshots.create_snapshot("my_collection")
      {:ok, %{"result" => %{"name" => "snapshot.snapshot", ...}}}

  """
  @spec create_snapshot(String.t(), boolean() | nil) :: {:ok, map()} | {:error, any()}
  def create_snapshot(collection_name, wait \\ nil) do
    path = "/collections/#{collection_name}/snapshots" |> Client.add_query_param("wait", wait)

    client()
    |> Tesla.post(path, %{})
    |> parse_response()
  end

  @doc """
  Get information about a specific snapshot.

  ## Parameters

  * `collection_name` **required** - Name of the collection
  * `snapshot_name` **required** - Name of the snapshot

  ## Example

      iex> Qdrant.Api.Http.Snapshots.get_snapshot("my_collection", "snapshot.snapshot")
      {:ok, %{...}}

  """
  @spec get_snapshot(String.t(), String.t()) :: {:ok, map()} | {:error, any()}
  def get_snapshot(collection_name, snapshot_name) do
    client()
    |> Tesla.get("/collections/#{collection_name}/snapshots/#{snapshot_name}")
    |> parse_response_binary()
  end

  @doc """
  Delete a specific snapshot.

  ## Parameters

  * `collection_name` **required** - Name of the collection
  * `snapshot_name` **required** - Name of the snapshot

  ## Example

      iex> Qdrant.Api.Http.Snapshots.delete_snapshot("my_collection", "snapshot.snapshot")
      {:ok, %{"result" => true, "status" => "ok"}}

  """
  @spec delete_snapshot(String.t(), String.t()) :: {:ok, map()} | {:error, any()}
  def delete_snapshot(collection_name, snapshot_name) do
    client()
    |> Tesla.delete("/collections/#{collection_name}/snapshots/#{snapshot_name}")
    |> parse_response()
  end

  @doc """
  Recover collection from a snapshot.

  ## Parameters

  * `collection_name` **required** - Name of the collection
  * `body` **required** - Snapshot recovery configuration
  * `wait` - Optional boolean, if true, wait for changes to actually happen
  * `priority` - Optional priority for snapshot recovery

  ## Example

      iex> body = %{location: "snapshot.snapshot"}
      iex> Qdrant.Api.Http.Snapshots.recover_from_snapshot("my_collection", body)
      {:ok, %{"result" => true, "status" => "ok"}}

  """
  @spec recover_from_snapshot(String.t(), map(), boolean() | nil, String.t() | nil) ::
          {:ok, map()} | {:error, any()}
  def recover_from_snapshot(collection_name, body, wait \\ nil, priority \\ nil) do
    path =
      "/collections/#{collection_name}/snapshots/recover"
      |> Client.add_query_param("wait", wait)
      |> Client.add_query_param("priority", priority)

    client()
    |> Tesla.put(path, body)
    |> parse_response()
  end

  @doc """
  Recover collection from an uploaded snapshot.

  ## Parameters

  * `collection_name` **required** - Name of the collection
  * `snapshot_data` **required** - Binary snapshot data (multipart form data)
  * `wait` - Optional boolean, if true, wait for changes to actually happen
  * `priority` - Optional priority for snapshot recovery
  * `checksum` - Optional SHA256 checksum to verify snapshot integrity

  ## Example

      iex> snapshot_data = File.read!("snapshot.snapshot")
      iex> Qdrant.Api.Http.Snapshots.recover_from_uploaded_snapshot("my_collection", snapshot_data)
      {:ok, %{"result" => true, "status" => "ok"}}

  """
  @spec recover_from_uploaded_snapshot(String.t(), binary(), boolean() | nil, String.t() | nil, String.t() | nil) ::
          {:ok, map()} | {:error, any()}
  def recover_from_uploaded_snapshot(
        collection_name,
        snapshot_data,
        wait \\ nil,
        priority \\ nil,
        checksum \\ nil
      ) do
    path =
      "/collections/#{collection_name}/snapshots/upload"
      |> Client.add_query_param("wait", wait)
      |> Client.add_query_param("priority", priority)
      |> Client.add_query_param("checksum", checksum)

    multipart = Tesla.Multipart.new() |> Tesla.Multipart.add_file_content(snapshot_data, "snapshot")

    client()
    |> Tesla.post(path, multipart)
    |> parse_response()
  end

  # Full snapshots

  @doc """
  List full snapshots.

  ## Example

      iex> Qdrant.Api.Http.Snapshots.list_full_snapshots()
      {:ok, %{"result" => %{"name" => "full-snapshot.snapshot", ...}}}

  """
  @spec list_full_snapshots() :: {:ok, map()} | {:error, any()}
  def list_full_snapshots do
    client()
    |> Tesla.get("/snapshots")
    |> parse_response()
  end

  @doc """
  Create a full snapshot.

  ## Parameters

  * `wait` - Optional boolean, if true, wait for changes to actually happen

  ## Example

      iex> Qdrant.Api.Http.Snapshots.create_full_snapshot()
      {:ok, %{"result" => %{"name" => "full-snapshot.snapshot", ...}}}

  """
  @spec create_full_snapshot(boolean() | nil) :: {:ok, map()} | {:error, any()}
  def create_full_snapshot(wait \\ nil) do
    path = "/snapshots" |> Client.add_query_param("wait", wait)

    client()
    |> Tesla.post(path, %{})
    |> parse_response()
  end

  @doc """
  Get information about a specific full snapshot.

  ## Parameters

  * `snapshot_name` **required** - Name of the snapshot

  ## Example

      iex> Qdrant.Api.Http.Snapshots.get_full_snapshot("full-snapshot.snapshot")
      {:ok, %{...}}

  """
  @spec get_full_snapshot(String.t()) :: {:ok, binary()} | {:error, any()}
  def get_full_snapshot(snapshot_name) do
    client()
    |> Tesla.get("/snapshots/#{snapshot_name}")
    |> parse_response_binary()
  end

  @doc """
  Delete a specific full snapshot.

  ## Parameters

  * `snapshot_name` **required** - Name of the snapshot

  ## Example

      iex> Qdrant.Api.Http.Snapshots.delete_full_snapshot("full-snapshot.snapshot")
      {:ok, %{"result" => true, "status" => "ok"}}

  """
  @spec delete_full_snapshot(String.t()) :: {:ok, map()} | {:error, any()}
  def delete_full_snapshot(snapshot_name) do
    client()
    |> Tesla.delete("/snapshots/#{snapshot_name}")
    |> parse_response()
  end

  # Shard snapshots

  @doc """
  List snapshots for a shard.

  ## Parameters

  * `collection_name` **required** - Name of the collection
  * `shard_id` **required** - ID of the shard

  ## Example

      iex> Qdrant.Api.Http.Snapshots.list_shard_snapshots("my_collection", 1)
      {:ok, %{"result" => %{"name" => "shard-snapshot.snapshot", ...}}}

  """
  @spec list_shard_snapshots(String.t(), integer()) :: {:ok, map()} | {:error, any()}
  def list_shard_snapshots(collection_name, shard_id) do
    client()
    |> Tesla.get("/collections/#{collection_name}/shards/#{shard_id}/snapshots")
    |> parse_response()
  end

  @doc """
  Create a snapshot for a shard.

  ## Parameters

  * `collection_name` **required** - Name of the collection
  * `shard_id` **required** - ID of the shard
  * `wait` - Optional boolean, if true, wait for changes to actually happen

  ## Example

      iex> Qdrant.Api.Http.Snapshots.create_shard_snapshot("my_collection", 1)
      {:ok, %{"result" => %{"name" => "shard-snapshot.snapshot", ...}}}

  """
  @spec create_shard_snapshot(String.t(), integer(), boolean() | nil) :: {:ok, map()} | {:error, any()}
  def create_shard_snapshot(collection_name, shard_id, wait \\ nil) do
    path =
      "/collections/#{collection_name}/shards/#{shard_id}/snapshots"
      |> Client.add_query_param("wait", wait)

    client()
    |> Tesla.post(path, %{})
    |> parse_response()
  end

  @doc """
  Get information about a specific shard snapshot.

  ## Parameters

  * `collection_name` **required** - Name of the collection
  * `shard_id` **required** - ID of the shard
  * `snapshot_name` **required** - Name of the snapshot

  ## Example

      iex> Qdrant.Api.Http.Snapshots.get_shard_snapshot("my_collection", 1, "shard-snapshot.snapshot")
      {:ok, %{...}}

  """
  @spec get_shard_snapshot(String.t(), integer(), String.t()) :: {:ok, binary()} | {:error, any()}
  def get_shard_snapshot(collection_name, shard_id, snapshot_name) do
    client()
    |> Tesla.get("/collections/#{collection_name}/shards/#{shard_id}/snapshots/#{snapshot_name}")
    |> parse_response_binary()
  end

  @doc """
  Delete a specific shard snapshot.

  ## Parameters

  * `collection_name` **required** - Name of the collection
  * `shard_id` **required** - ID of the shard
  * `snapshot_name` **required** - Name of the snapshot

  ## Example

      iex> Qdrant.Api.Http.Snapshots.delete_shard_snapshot("my_collection", 1, "shard-snapshot.snapshot")
      {:ok, %{"result" => true, "status" => "ok"}}

  """
  @spec delete_shard_snapshot(String.t(), integer(), String.t()) :: {:ok, map()} | {:error, any()}
  def delete_shard_snapshot(collection_name, shard_id, snapshot_name) do
    client()
    |> Tesla.delete("/collections/#{collection_name}/shards/#{shard_id}/snapshots/#{snapshot_name}")
    |> parse_response()
  end

  @doc """
  Recover shard from a snapshot.

  ## Parameters

  * `collection_name` **required** - Name of the collection
  * `shard_id` **required** - ID of the shard
  * `body` **required** - Snapshot recovery configuration
  * `wait` - Optional boolean, if true, wait for changes to actually happen
  * `priority` - Optional priority for snapshot recovery

  ## Example

      iex> body = %{location: "shard-snapshot.snapshot"}
      iex> Qdrant.Api.Http.Snapshots.recover_shard_from_snapshot("my_collection", 1, body)
      {:ok, %{"result" => true, "status" => "ok"}}

  """
  @spec recover_shard_from_snapshot(String.t(), integer(), map(), boolean() | nil, String.t() | nil) ::
          {:ok, map()} | {:error, any()}
  def recover_shard_from_snapshot(collection_name, shard_id, body, wait \\ nil, priority \\ nil) do
    path =
      "/collections/#{collection_name}/shards/#{shard_id}/snapshots/recover"
      |> Client.add_query_param("wait", wait)
      |> Client.add_query_param("priority", priority)

    client()
    |> Tesla.put(path, body)
    |> parse_response()
  end

  @doc """
  Recover shard from an uploaded snapshot.

  ## Parameters

  * `collection_name` **required** - Name of the collection
  * `shard_id` **required** - ID of the shard
  * `snapshot_data` **required** - Binary snapshot data (multipart form data)
  * `wait` - Optional boolean, if true, wait for changes to actually happen
  * `priority` - Optional priority for snapshot recovery

  ## Example

      iex> snapshot_data = File.read!("shard-snapshot.snapshot")
      iex> Qdrant.Api.Http.Snapshots.recover_shard_from_uploaded_snapshot("my_collection", 1, snapshot_data)
      {:ok, %{"result" => true, "status" => "ok"}}

  """
  @spec recover_shard_from_uploaded_snapshot(String.t(), integer(), binary(), boolean() | nil, String.t() | nil) ::
          {:ok, map()} | {:error, any()}
  def recover_shard_from_uploaded_snapshot(collection_name, shard_id, snapshot_data, wait \\ nil, priority \\ nil) do
    path =
      "/collections/#{collection_name}/shards/#{shard_id}/snapshots/upload"
      |> Client.add_query_param("wait", wait)
      |> Client.add_query_param("priority", priority)

    multipart = Tesla.Multipart.new() |> Tesla.Multipart.add_file_content(snapshot_data, "snapshot")

    client()
    |> Tesla.post(path, multipart)
    |> parse_response()
  end

  # Private helpers
  defp parse_response({:ok, %Tesla.Env{status: 200, body: body}}) do
    {:ok, body}
  end

  defp parse_response({:ok, %Tesla.Env{status: 202, body: body}}) do
    {:ok, body}
  end

  defp parse_response({:error, reason}) do
    {:error, reason}
  end

  defp parse_response({:ok, %Tesla.Env{} = env}) do
    {:error, %{status: env.status, body: env.body}}
  end

  defp parse_response_binary({:ok, %Tesla.Env{status: 200, body: body}}) when is_binary(body) do
    {:ok, body}
  end

  defp parse_response_binary({:ok, %Tesla.Env{status: 200, body: body}}) do
    {:ok, body}
  end

  defp parse_response_binary({:error, reason}) do
    {:error, reason}
  end

  defp parse_response_binary({:ok, %Tesla.Env{} = env}) do
    {:error, %{status: env.status, body: env.body}}
  end
end
