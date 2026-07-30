defmodule Qdrant.Api.Http.Collections do
  @moduledoc """
  Qdrant API Collections.

  Collections are searchable collections of points.
  """

  alias Qdrant.Api.Http.Request
  alias Qdrant.{Client, Config, Types}

  @doc """
  Get list name of all existing collections.

  ## Network example (not a doctest)

      client = Qdrant.Client.new!()
      Qdrant.Api.Http.Collections.list_collections(client)
      {:ok, %{"result" => %{"collections" => [...]}}}

  """
  @spec list_collections(Client.t(), Types.request_options()) :: Types.result(map())
  def list_collections(%Client{} = client, opts \\ []) do
    Request.request(client, :get, "/collections", opts)
  end

  @spec list_collections() :: Types.result(map())
  def list_collections, do: with_default_client(&list_collections(&1, []))

  @doc """
  Get detailed information about specified existing collection.

  ## Parameters

  * `collection_name` - The name of the collection to retrieve information from.

  ## Network example (not a doctest)

      client = Qdrant.Client.new!()
      Qdrant.Api.Http.Collections.get_collection(client, "my_collection")
      {:ok, %{"result" => %{"name" => "my_collection", ...}}}

  """
  @spec get_collection(Client.t(), String.t(), Types.request_options()) :: Types.result(map())
  def get_collection(%Client{} = client, collection_name, opts \\ []) do
    Request.request(client, :get, "/collections/#{Request.segment(collection_name)}", opts)
  end

  @spec get_collection(String.t()) :: Types.result(map())
  def get_collection(collection_name), do: with_default_client(&get_collection(&1, collection_name, []))

  @doc """
  Retrieves parameters from the specified collection.

  Alias for `get_collection/1` for backward compatibility.

  ## Parameters

  * `collection_name` - The name of the collection to retrieve parameters from.

  ## Network example (not a doctest)

      client = Qdrant.Client.new!()
      Qdrant.Api.Http.Collections.get_collection_details(client, "my_collection")
      {:ok, %{"result" => %{"name" => "my_collection", ...}}}
  """
  @spec get_collection_details(Client.t(), String.t(), Types.request_options()) :: Types.result(map())
  def get_collection_details(%Client{} = client, collection_name, opts \\ []) do
    get_collection(client, collection_name, opts)
  end

  @spec get_collection_details(String.t()) :: Types.result(map())
  def get_collection_details(collection_name) do
    with_default_client(&get_collection_details(&1, collection_name, []))
  end

  @doc """
  Create new collection with given parameters.

  ## Parameters

  * `collection_name` - Name of the new collection
  * `body` - Collection configuration parameters (must include `vectors` key)
  * `opts` - Options, including `:timeout` in seconds for operation commit

  ## Network example (not a doctest)

      client = Qdrant.Client.new!()
      body = %{vectors: %{size: 128, distance: "Cosine"}}
      Qdrant.Api.Http.Collections.create_collection(client, "my_collection", body)
      {:ok, %{"result" => true, "status" => "ok"}}

  """
  @spec create_collection(Client.t(), String.t(), Types.request_body(), Types.request_options()) :: Types.result(map())
  def create_collection(%Client{} = client, collection_name, body, opts) do
    Request.request(client, :put, "/collections/#{Request.segment(collection_name)}",
      query: [timeout: Keyword.get(opts, :timeout)],
      body: body
    )
  end

  @spec create_collection(Client.t(), String.t(), Types.request_body()) :: Types.result(map())
  def create_collection(%Client{} = client, collection_name, body) do
    create_collection(client, collection_name, body, [])
  end

  @spec create_collection(String.t(), Types.request_body(), integer() | nil) :: Types.result(map())
  def create_collection(collection_name, body, timeout) do
    with_default_client(&create_collection(&1, collection_name, body, timeout: timeout))
  end

  @spec create_collection(String.t(), Types.request_body()) :: Types.result(map())
  def create_collection(collection_name, body), do: create_collection(collection_name, body, nil)

  @doc """
  Update parameters of the existing collection.

  ## Parameters

  * `collection_name` - Name of the collection to update
  * `body` - New collection parameters
  * `opts` - Options, including `:timeout` in seconds for operation commit

  ## Network example (not a doctest)

      client = Qdrant.Client.new!()
      body = %{optimizers_config: %{deleted_threshold: 0.2}}
      Qdrant.Api.Http.Collections.update_collection(client, "my_collection", body)
      {:ok, %{"result" => true, "status" => "ok"}}

  """
  @spec update_collection(Client.t(), String.t(), Types.request_body(), Types.request_options()) :: Types.result(map())
  def update_collection(%Client{} = client, collection_name, body, opts) do
    Request.request(client, :patch, "/collections/#{Request.segment(collection_name)}",
      query: [timeout: Keyword.get(opts, :timeout)],
      body: body
    )
  end

  @spec update_collection(Client.t(), String.t(), Types.request_body()) :: Types.result(map())
  def update_collection(%Client{} = client, collection_name, body) do
    update_collection(client, collection_name, body, [])
  end

  @spec update_collection(String.t(), Types.request_body(), integer() | nil) :: Types.result(map())
  def update_collection(collection_name, body, timeout) do
    with_default_client(&update_collection(&1, collection_name, body, timeout: timeout))
  end

  @spec update_collection(String.t(), Types.request_body()) :: Types.result(map())
  def update_collection(collection_name, body), do: update_collection(collection_name, body, nil)

  @doc """
  Drop collection and all associated data.

  ## Parameters

  * `collection_name` - Name of the collection to delete
  * `opts` - Options, including `:timeout` in seconds for operation commit

  ## Network example (not a doctest)

      client = Qdrant.Client.new!()
      Qdrant.Api.Http.Collections.delete_collection(client, "my_collection")
      {:ok, %{"result" => true, "status" => "ok"}}

  """
  @spec delete_collection(Client.t(), String.t(), Types.request_options()) :: Types.result(map())
  def delete_collection(%Client{} = client, collection_name, opts) do
    Request.request(client, :delete, "/collections/#{Request.segment(collection_name)}",
      query: [timeout: Keyword.get(opts, :timeout)]
    )
  end

  @spec delete_collection(Client.t(), String.t()) :: Types.result(map())
  def delete_collection(%Client{} = client, collection_name) do
    delete_collection(client, collection_name, [])
  end

  @spec delete_collection(String.t(), integer() | nil) :: Types.result(map())
  def delete_collection(collection_name, timeout) do
    with_default_client(&delete_collection(&1, collection_name, timeout: timeout))
  end

  @spec delete_collection(String.t()) :: Types.result(map())
  def delete_collection(collection_name), do: delete_collection(collection_name, nil)

  @doc """
  Check if collection exists.

  ## Parameters

  * `collection_name` - Name of the collection to check

  ## Network example (not a doctest)

      client = Qdrant.Client.new!()
      Qdrant.Api.Http.Collections.collection_exists(client, "my_collection")
      {:ok, %{"result" => %{"exists" => true}}}

  """
  @spec collection_exists(Client.t(), String.t(), Types.request_options()) :: Types.result(map())
  def collection_exists(%Client{} = client, collection_name, opts \\ []) do
    Request.request(client, :get, "/collections/#{Request.segment(collection_name)}/exists", opts)
  end

  @spec collection_exists(String.t()) :: Types.result(map())
  def collection_exists(collection_name), do: with_default_client(&collection_exists(&1, collection_name, []))

  defp with_default_client(operation) do
    with {:ok, opts} <- Config.client_options(),
         {:ok, client} <- Client.new(opts) do
      operation.(client)
    end
  end
end
