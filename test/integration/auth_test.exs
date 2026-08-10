defmodule Qdrant.Integration.AuthTest do
  use ExUnit.Case, async: false

  @moduletag :integration

  test "an explicit API-key client can reach the configured server" do
    case System.get_env("QDRANT_API_KEY") do
      nil ->
        :ok

      "" ->
        :ok

      key ->
        client =
          Qdrant.Client.new!(
            url: System.get_env("QDRANT_URL") || "http://127.0.0.1:6333",
            api_key: key,
            allow_insecure_api_key: true
          )

        assert {:ok, %{"title" => _title}} = Qdrant.root(client)
    end
  end
end
