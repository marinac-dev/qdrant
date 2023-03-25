defmodule Qdrant.Api.Http.Client do
  @moduledoc """
  Qdrant.Api.Client is a Tesla-based client for the Qdrant API.
  The module provides methods for interacting with the Qdrant API server.

  ## Example
      iex> Qdrant.Api.Client.get("/collections")
      {:ok, %Tesla.Env{status: 200, body: %{"collections" => [...]}}}
  """

  defmacro __using__(_opts) do
    quote do
      use Tesla, docs: false
      plug Tesla.Middleware.BaseUrl, get_url()
      plug Tesla.Middleware.JSON

      defp get_url() do
        case Application.get_env(:qdrant, :database_url) do
          nil -> raise "Qdrant database url is not set"
          url -> url <> api_path()
        end
      end

      import(Qdrant.Api.Http.Client, only: [url: 1])
    end
  end

  defmacro url(path) do
    quote do
      def api_path, do: unquote(path)
    end
  end
end
