defmodule Qdrant.Api.Http.Client do
  @moduledoc """
  Qdrant.Api.Http.Client provides a Tesla-based client for the Qdrant API.

  This module provides a `client/1` function that returns a configured Tesla client
  with appropriate middleware for base URL, headers, and JSON encoding/decoding.

  ## Example

      iex> client = Qdrant.Api.Http.Client.client()
      iex> Tesla.get(client, "/collections")
      {:ok, %Tesla.Env{status: 200, body: %{"collections" => []}}}

  """

  @doc """
  Creates a Tesla client with Qdrant API configuration.

  ## Options

  - `:base_path` - Optional base path to prepend to all requests (default: "")

  ## Example

      iex> client = Qdrant.Api.Http.Client.client()
      iex> Tesla.get(client, "/collections")
      {:ok, %Tesla.Env{status: 200, body: %{"collections" => []}}}

  """
  def client(opts \\ []) do
    base_path = Keyword.get(opts, :base_path, "")

    middleware = [
      {Tesla.Middleware.BaseUrl, Qdrant.Config.base_url() <> base_path},
      {Tesla.Middleware.JSON, engine: JSON}
    ]

    middleware =
      case Qdrant.Config.get_api_key() do
        nil -> middleware
        key -> [{Tesla.Middleware.Headers, [{"api-key", key}]} | middleware]
      end

    adapter = Qdrant.Config.get_adapter(opts)

    Tesla.client(middleware, adapter)
  end

  @doc """
  Helper function to build query string from parameters.

  ## Examples

      iex> add_query_param("/path", "foo", "bar")
      "/path?foo=bar"

      iex> add_query_param("/path?existing=value", "foo", "bar")
      "/path?existing=value&foo=bar"

      iex> add_query_param("/path", "foo", nil)
      "/path"
  """
  def add_query_param(path, _key, nil), do: path
  def add_query_param(path, key, value) when is_binary(path) do
    separator = if String.contains?(path, "?"), do: "&", else: "?"
    path <> separator <> URI.encode_query([{key, value}])
  end
end
