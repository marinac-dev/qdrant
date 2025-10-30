defmodule Qdrant.Api.Http.Collections do
  @moduledoc """
  Qdrant API Collections.

  Collections are searchable collections of points.
  """

  use Qdrant.Utils.Types

  alias Qdrant.Api.Http.Client

  defp client, do: Client.client()

  @doc """
  Get list name of all existing collections.

  ## Example

      iex> Qdrant.Api.Http.Collections.list_collections()
      {:ok, %{"result" => %{"collections" => [...]}}}

  """
  @spec list_collections() :: {:ok, map()} | {:error, any()}
  def list_collections do
    client()
    |> Tesla.get("/collections")
    |> parse_response()
  end

  @doc """
  Get detailed information about specified existing collection.

  ## Parameters
  * `collection_name` - The name of the collection to retrieve information from.

  ## Example

      iex> Qdrant.Api.Http.Collections.get_collection("my_collection")
      {:ok, %{"result" => %{"name" => "my_collection", ...}}}

  """
  @spec get_collection(String.t()) :: {:ok, map()} | {:error, any()}
  def get_collection(collection_name) do
    client()
    |> Tesla.get("/collections/#{collection_name}")
    |> parse_response()
  end

  @doc """
  Retrieves parameters from the specified collection.

  Alias for `get_collection/1` for backward compatibility.

  ## Parameters
  * `collection_name` - The name of the collection to retrieve parameters from.

  ## Example

      iex> Qdrant.Api.Http.Collections.get_collection_details("my_collection")
      {:ok, %{"result" => %{"name" => "my_collection", ...}}}
  """
  @spec get_collection_details(String.t()) :: {:ok, map()} | {:error, any()}
  def get_collection_details(collection_name), do: get_collection(collection_name)

  @doc """
  Create new collection with given parameters.

  ## Parameters
  * `collection_name` - Name of the new collection
  * `body` - Collection configuration parameters (must include `vectors` key)
  * `timeout` - Optional timeout in seconds for operation commit

  ## Example

      iex> body = %{vectors: %{size: 128, distance: "Cosine"}}
      iex> Qdrant.Api.Http.Collections.create_collection("my_collection", body)
      {:ok, %{"result" => true, "status" => "ok"}}

  """
  @spec create_collection(String.t(), map(), integer() | nil) :: {:ok, map()} | {:error, any()}
  def create_collection(collection_name, body, timeout \\ nil) do
    path =
      "/collections/#{collection_name}"
      |> Client.add_query_param("timeout", timeout)

    client()
    |> Tesla.put(path, body)
    |> parse_response()
  end

  @doc """
  Update parameters of the existing collection.

  ## Parameters
  * `collection_name` - Name of the collection to update
  * `body` - New collection parameters
  * `timeout` - Optional timeout in seconds for operation commit

  ## Example

      iex> body = %{optimizers_config: %{deleted_threshold: 0.2}}
      iex> Qdrant.Api.Http.Collections.update_collection("my_collection", body)
      {:ok, %{"result" => true, "status" => "ok"}}

  """
  @spec update_collection(String.t(), map(), integer() | nil) :: {:ok, map()} | {:error, any()}
  def update_collection(collection_name, body, timeout \\ nil) do
    path =
      "/collections/#{collection_name}"
      |> Client.add_query_param("timeout", timeout)

    client()
    |> Tesla.patch(path, body)
    |> parse_response()
  end

  @doc """
  Drop collection and all associated data.

  ## Parameters
  * `collection_name` - Name of the collection to delete
  * `timeout` - Optional timeout in seconds for operation commit

  ## Example

      iex> Qdrant.Api.Http.Collections.delete_collection("my_collection")
      {:ok, %{"result" => true, "status" => "ok"}}

  """
  @spec delete_collection(String.t(), integer() | nil) :: {:ok, map()} | {:error, any()}
  def delete_collection(collection_name, timeout \\ nil) do
    path =
      "/collections/#{collection_name}"
      |> Client.add_query_param("timeout", timeout)

    client()
    |> Tesla.delete(path)
    |> parse_response()
  end

  @doc """
  Check if collection exists.

  ## Parameters
  * `collection_name` - Name of the collection to check

  ## Example

      iex> Qdrant.Api.Http.Collections.collection_exists("my_collection")
      {:ok, %{"result" => %{"exists" => true}}}

  """
  @spec collection_exists(String.t()) :: {:ok, map()} | {:error, any()}
  def collection_exists(collection_name) do
    client()
    |> Tesla.get("/collections/#{collection_name}/exists")
    |> parse_response()
  end

  # Private helpers
  defp parse_response({:ok, %Tesla.Env{status: 200, body: body}}) do
    {:ok, body}
  end

  defp parse_response({:ok, %Tesla.Env{status: 404, body: body}}) do
    {:error, body}
  end

  defp parse_response({:error, reason}) do
    {:error, reason}
  end

  defp parse_response({:ok, %Tesla.Env{} = env}) do
    {:error, %{status: env.status, body: env.body}}
  end
end
