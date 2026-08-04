defmodule Qdrant.Api.Http.Indexes do
  @moduledoc """
  Qdrant API Field Indexes operations.

  Field indexes allow to speed up filtering and sorting operations on payload fields.
  """

  alias Qdrant.Api.Http.Request
  alias Qdrant.{Client, Config, Types}

  @doc """
  Create index for field in collection.

  ## Parameters

  * `collection_name` **required** - Name of the collection
  * `body` **required** - Field index configuration
  * `opts` - Options, including `:wait`, `:ordering`, and `:timeout`

  ## Network example (not a doctest)

      client = Qdrant.Client.new!()
      body = %{field_name: "category", field_schema: "keyword"}
      Qdrant.Api.Http.Indexes.create_field_index(client, "my_collection", body)
      {:ok, %{"result" => %{...}, "status" => "ok"}}

  """
  @spec create_field_index(Client.t(), String.t(), Types.request_body(), Types.request_options()) :: Types.result(map())
  def create_field_index(%Client{} = client, collection_name, body, opts) do
    Request.request(client, :put, "/collections/#{Request.segment(collection_name)}/index",
      query: [
        wait: Keyword.get(opts, :wait),
        ordering: Keyword.get(opts, :ordering),
        timeout: Keyword.get(opts, :timeout)
      ],
      body: body
    )
  end

  @spec create_field_index(
          String.t(),
          Types.request_body(),
          boolean() | nil,
          Types.ordering() | nil
        ) :: Types.result(map())
  def create_field_index(collection_name, body, wait, ordering) do
    with_default_client(&create_field_index(&1, collection_name, body, wait: wait, ordering: ordering))
  end

  @spec create_field_index(
          String.t(),
          Types.request_body(),
          boolean() | nil,
          Types.ordering() | nil,
          integer() | nil
        ) :: Types.result(map())
  def create_field_index(collection_name, body, wait, ordering, timeout) do
    with_default_client(
      &create_field_index(&1, collection_name, body, wait: wait, ordering: ordering, timeout: timeout)
    )
  end

  @spec create_field_index(Client.t(), String.t(), Types.request_body()) :: Types.result(map())
  def create_field_index(%Client{} = client, collection_name, body) do
    create_field_index(client, collection_name, body, [])
  end

  @spec create_field_index(String.t(), Types.request_body(), boolean() | nil) :: Types.result(map())
  def create_field_index(collection_name, body, wait), do: create_field_index(collection_name, body, wait, nil)

  @spec create_field_index(String.t(), Types.request_body()) :: Types.result(map())
  def create_field_index(collection_name, body), do: create_field_index(collection_name, body, nil, nil)

  @doc """
  Delete index for field in collection.

  ## Parameters

  * `collection_name` **required** - Name of the collection
  * `field_name` **required** - Name of the field to delete index for
  * `opts` - Options, including `:wait`, `:ordering`, and `:timeout`

  ## Network example (not a doctest)

      client = Qdrant.Client.new!()
      Qdrant.Api.Http.Indexes.delete_field_index(client, "my_collection", "category")
      {:ok, %{"result" => %{...}, "status" => "ok"}}

  """
  @spec delete_field_index(Client.t(), String.t(), String.t(), Types.request_options()) :: Types.result(map())
  def delete_field_index(%Client{} = client, collection_name, field_name, opts) do
    Request.request(
      client,
      :delete,
      "/collections/#{Request.segment(collection_name)}/index/#{Request.segment(field_name)}",
      query: [
        wait: Keyword.get(opts, :wait),
        ordering: Keyword.get(opts, :ordering),
        timeout: Keyword.get(opts, :timeout)
      ]
    )
  end

  @spec delete_field_index(
          String.t(),
          String.t(),
          boolean() | nil,
          Types.ordering() | nil
        ) :: Types.result(map())
  def delete_field_index(collection_name, field_name, wait, ordering) do
    with_default_client(&delete_field_index(&1, collection_name, field_name, wait: wait, ordering: ordering))
  end

  @spec delete_field_index(
          String.t(),
          String.t(),
          boolean() | nil,
          Types.ordering() | nil,
          integer() | nil
        ) :: Types.result(map())
  def delete_field_index(collection_name, field_name, wait, ordering, timeout) do
    with_default_client(
      &delete_field_index(&1, collection_name, field_name,
        wait: wait,
        ordering: ordering,
        timeout: timeout
      )
    )
  end

  @spec delete_field_index(Client.t(), String.t(), String.t()) :: Types.result(map())
  def delete_field_index(%Client{} = client, collection_name, field_name) do
    delete_field_index(client, collection_name, field_name, [])
  end

  @spec delete_field_index(String.t(), String.t(), boolean() | nil) :: Types.result(map())
  def delete_field_index(collection_name, field_name, wait),
    do: delete_field_index(collection_name, field_name, wait, nil)

  @spec delete_field_index(String.t(), String.t()) :: Types.result(map())
  def delete_field_index(collection_name, field_name), do: delete_field_index(collection_name, field_name, nil, nil)

  defp with_default_client(operation) do
    with {:ok, opts} <- Config.client_options(),
         {:ok, client} <- Client.new(opts) do
      operation.(client)
    end
  end
end
