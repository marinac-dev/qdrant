defmodule Qdrant do
  @moduledoc """
  Documentation for Qdrant.
  """

  use Qdrant.Api.Wrapper

  @doc """

  """
  def create_collection(collection_name, body, timeout \\ nil) do
    api_call("Collections", :create_collection, [collection_name, body, timeout])
  end

  def list_collections() do
    api_call("Collections", :list_collections, [])
  end

  def collection_info(collection_name) do
    api_call("Collections", :collection_info, [collection_name])
  end
end
