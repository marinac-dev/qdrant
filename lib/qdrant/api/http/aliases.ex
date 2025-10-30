defmodule Qdrant.Api.Http.Aliases do
  @moduledoc """
  Qdrant API Aliases operations.

  Aliases allow to give names to collections and use them instead of collection names.
  """

  alias Qdrant.Api.Http.Client

  defp client, do: Client.client()

  @doc """
  Update aliases of collections.

  ## Parameters

  * `body` **required** - Alias update operations (create, delete, rename)
  * `timeout` - Optional timeout in seconds for operation commit

  ## Example

      iex> body = %{actions: [%{create_alias: %{collection_name: "my_collection", alias_name: "my_alias"}}]}
      iex> Qdrant.Api.Http.Aliases.update_aliases(body)
      {:ok, %{"result" => true, "status" => "ok"}}

  """
  @spec update_aliases(map(), integer() | nil) :: {:ok, map()} | {:error, any()}
  def update_aliases(body, timeout \\ nil) do
    path = "/collections/aliases" |> Client.add_query_param("timeout", timeout)

    client()
    |> Tesla.post(path, body)
    |> parse_response()
  end

  @doc """
  Get aliases for a specific collection.

  ## Parameters

  * `collection_name` **required** - Name of the collection

  ## Example

      iex> Qdrant.Api.Http.Aliases.get_collection_aliases("my_collection")
      {:ok, %{"result" => %{"aliases" => [...]}}}

  """
  @spec get_collection_aliases(String.t()) :: {:ok, map()} | {:error, any()}
  def get_collection_aliases(collection_name) do
    client()
    |> Tesla.get("/collections/#{collection_name}/aliases")
    |> parse_response()
  end

  @doc """
  Get list of all existing collections aliases.

  ## Example

      iex> Qdrant.Api.Http.Aliases.get_collections_aliases()
      {:ok, %{"result" => %{"aliases" => [...]}}}

  """
  @spec get_collections_aliases() :: {:ok, map()} | {:error, any()}
  def get_collections_aliases do
    client()
    |> Tesla.get("/collections/aliases")
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
