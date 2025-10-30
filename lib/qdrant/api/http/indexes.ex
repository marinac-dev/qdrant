defmodule Qdrant.Api.Http.Indexes do
  @moduledoc """
  Qdrant API Field Indexes operations.

  Field indexes allow to speed up filtering and sorting operations on payload fields.
  """

  use Qdrant.Utils.Types

  alias Qdrant.Api.Http.Client

  defp client, do: Client.client()

  @doc """
  Create index for field in collection.

  ## Parameters

  * `collection_name` **required** - Name of the collection
  * `body` **required** - Field index configuration
  * `wait` - Optional boolean, if true, wait for changes to actually happen
  * `ordering` - Optional ordering guarantees for the operation

  ## Example

      iex> body = %{field_name: "category", field_schema: "keyword"}
      iex> Qdrant.Api.Http.Indexes.create_field_index("my_collection", body)
      {:ok, %{"result" => %{...}, "status" => "ok"}}

  """
  @spec create_field_index(String.t(), map(), boolean() | nil, ordering() | nil) ::
          {:ok, map()} | {:error, any()}
  def create_field_index(collection_name, body, wait \\ nil, ordering \\ nil) do
    path =
      "/collections/#{collection_name}/index"
      |> Client.add_query_param("wait", wait)
      |> Client.add_query_param("ordering", ordering)

    client()
    |> Tesla.put(path, body)
    |> parse_response()
  end

  @doc """
  Delete index for field in collection.

  ## Parameters

  * `collection_name` **required** - Name of the collection
  * `field_name` **required** - Name of the field to delete index for
  * `wait` - Optional boolean, if true, wait for changes to actually happen
  * `ordering` - Optional ordering guarantees for the operation

  ## Example

      iex> Qdrant.Api.Http.Indexes.delete_field_index("my_collection", "category")
      {:ok, %{"result" => %{...}, "status" => "ok"}}

  """
  @spec delete_field_index(String.t(), String.t(), boolean() | nil, ordering() | nil) ::
          {:ok, map()} | {:error, any()}
  def delete_field_index(collection_name, field_name, wait \\ nil, ordering \\ nil) do
    path =
      "/collections/#{collection_name}/index/#{field_name}"
      |> Client.add_query_param("wait", wait)
      |> Client.add_query_param("ordering", ordering)

    client()
    |> Tesla.delete(path)
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
