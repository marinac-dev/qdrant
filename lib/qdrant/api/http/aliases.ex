defmodule Qdrant.Api.Http.Aliases do
  @moduledoc """
  Qdrant API Aliases operations.

  Aliases allow to give names to collections and use them instead of collection names.
  """

  alias Qdrant.Api.Http.Request
  alias Qdrant.{Client, Config, Types}

  @doc """
  Update aliases of collections.

  ## Parameters

  * `body` **required** - Alias update operations (create, delete, rename)
  * `opts` - Options, including `:timeout` in seconds for operation commit

  ## Network example (not a doctest)

      client = Qdrant.Client.new!()
      body = %{actions: [%{create_alias: %{collection_name: "my_collection", alias_name: "my_alias"}}]}
      Qdrant.Api.Http.Aliases.update_aliases(client, body)
      {:ok, %{"result" => true, "status" => "ok"}}

  """
  @spec update_aliases(Client.t(), Types.request_body(), Types.request_options()) :: Types.result(map())
  def update_aliases(%Client{} = client, body, opts) do
    Request.request(client, :post, "/collections/aliases",
      query: [timeout: Keyword.get(opts, :timeout)],
      body: body
    )
  end

  @spec update_aliases(Client.t(), Types.request_body()) :: Types.result(map())
  def update_aliases(%Client{} = client, body), do: update_aliases(client, body, [])

  @spec update_aliases(Types.request_body(), integer() | nil) :: Types.result(map())
  def update_aliases(body, timeout) do
    with_default_client(&update_aliases(&1, body, timeout: timeout))
  end

  @spec update_aliases(Types.request_body()) :: Types.result(map())
  def update_aliases(body), do: update_aliases(body, nil)

  @doc """
  Get aliases for a specific collection.

  ## Parameters

  * `collection_name` **required** - Name of the collection

  ## Network example (not a doctest)

      client = Qdrant.Client.new!()
      Qdrant.Api.Http.Aliases.get_collection_aliases(client, "my_collection")
      {:ok, %{"result" => %{"aliases" => [...]}}}

  """
  @spec get_collection_aliases(Client.t(), String.t(), Types.request_options()) :: Types.result(map())
  def get_collection_aliases(%Client{} = client, collection_name, opts \\ []) do
    Request.request(client, :get, "/collections/#{Request.segment(collection_name)}/aliases", opts)
  end

  @spec get_collection_aliases(String.t()) :: Types.result(map())
  def get_collection_aliases(collection_name) do
    with_default_client(&get_collection_aliases(&1, collection_name, []))
  end

  @doc """
  Get list of all existing collections aliases.

  ## Network example (not a doctest)

      client = Qdrant.Client.new!()
      Qdrant.Api.Http.Aliases.get_collections_aliases(client)
      {:ok, %{"result" => %{"aliases" => [...]}}}

  """
  @spec get_collections_aliases(Client.t(), Types.request_options()) :: Types.result(map())
  def get_collections_aliases(%Client{} = client, opts \\ []) do
    Request.request(client, :get, "/aliases", opts)
  end

  @spec get_collections_aliases() :: Types.result(map())
  def get_collections_aliases, do: with_default_client(&get_collections_aliases(&1, []))

  defp with_default_client(operation) do
    with {:ok, opts} <- Config.client_options(),
         {:ok, client} <- Client.new(opts) do
      operation.(client)
    end
  end
end
