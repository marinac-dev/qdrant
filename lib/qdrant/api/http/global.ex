defmodule Qdrant.Api.Http.Service do
  @moduledoc """
  Fetch various telemetry data and all collections aliases.
  """
  use Qdrant.Api.Http.Client

  @doc false
  scope ""

  @doc """
  Get list of all existing collections aliases [See more on qdrant](https://qdrant.github.io/qdrant/redoc/index.html#tag/collections/operation/get_collections_aliases)

  ## Example

      iex> Qdrant.list_collections_aliases()
      %{:ok, %{time: 0, status: "ok", result: %{}, aliases: [%{alias_name: "string", collection_name: "string"}]}}
  """
  @spec list_collections_aliases() :: {:ok, map()} | {:error, any()}
  def list_collections_aliases() do
    path = "/aliases"
    get(path)
  end

  @doc """
  Collect telemetry data

  Collect telemetry data including app info, system info, collections info, cluster info, configs and statistics
  """
  @spec telemetry() :: {:ok, map()} | {:error, any()}
  def telemetry() do
    path = "/telemetry"
    get(path)
  end

  @doc """
  Collect Prometheus metrics data

  Collect metrics data including app info, collections info, cluster info and statistics
  """
  @spec metrics() :: {:ok, map()} | {:error, any()}
  def metrics() do
    path = "/metrics"
    get(path)
  end

  @doc """
  Get lock options

  Get lock options. If write is locked, all write operations and collection creation are forbidden
  """
  @spec lock_options() :: {:ok, map()} | {:error, any()}
  def lock_options() do
    path = "/locks"
    get(path)
  end

  @doc """
  Set lock options

  Set lock options. If write is locked, all write operations and collection creation are forbidden. Returns previous lock options

  ## Request body schema

  - `error_message` - Error message to return on write operations

  - `write` - Write lock flag. If true, all write operations and collection creation are forbidden

  ## Example

      iex> Qdrant.set_lock_options(%{error_message: "string", write: true})
      %{:ok, %{time: 0, status: "ok", result: %{error_message: "string", write: true}}}
  """
  @spec set_lock_options(map()) :: {:ok, map()} | {:error, any()}
  def set_lock_options(body) do
    path = "/locks"
    post(path, body)
  end
end
