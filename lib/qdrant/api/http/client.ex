defmodule Qdrant.Api.Http.Client do
  @moduledoc false

  alias Qdrant.Api.Http.Request

  @spec client(keyword()) :: Tesla.Client.t()
  def client(opts \\ []), do: Qdrant.Client.new!(opts).tesla

  @spec add_query_param(String.t(), String.t() | atom(), term()) :: String.t()
  def add_query_param(path, key, value), do: Request.query(path, [{key, value}])
end
