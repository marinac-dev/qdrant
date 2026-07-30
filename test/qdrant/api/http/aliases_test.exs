defmodule Qdrant.Api.Http.AliasesTest do
  use ExUnit.Case, async: true

  alias Qdrant.Api.Http.Aliases
  alias Qdrant.{Client, Error}

  test "sends alias requests with encoded paths, queries, and JSON bodies" do
    client = client(self())
    body = %{actions: [%{delete_alias: %{alias_name: "old"}}]}

    assert {:ok, %{"result" => true}} = Aliases.update_aliases(client, body, timeout: nil)
    update_env = assert_request(:post, "https://example.test/collections/aliases")
    assert {"content-type", "application/json"} in update_env.headers
    assert Jason.decode!(update_env.body) == %{"actions" => [%{"delete_alias" => %{"alias_name" => "old"}}]}

    assert {:ok, %{"result" => true}} = Aliases.update_aliases(client, body, timeout: 5)
    assert_request(:post, "https://example.test/collections/aliases?timeout=5")

    assert {:ok, %{"result" => true}} = Aliases.get_collection_aliases(client, "team/blue?")
    assert_request(:get, "https://example.test/collections/team%2Fblue%3F/aliases")

    assert {:ok, %{"result" => true}} = Aliases.get_collections_aliases(client)
    assert_request(:get, "https://example.test/aliases")
  end

  test "returns a structured error for a non-success response" do
    client = client(self(), 400)

    assert {:error,
            %Error{
              kind: :http,
              status: 400,
              body: %{"status" => "invalid aliases"},
              method: :post,
              url: "https://example.test/collections/aliases",
              request_id: "req-alias"
            }} = Aliases.update_aliases(client, %{actions: []})
  end

  defp client(test_pid, status \\ 200) do
    adapter = fn env ->
      send(test_pid, {:request, env})

      body = if status in 200..299, do: %{"result" => true}, else: %{"status" => "invalid aliases"}
      {:ok, %{env | status: status, headers: [{"x-request-id", "req-alias"}], body: body}}
    end

    Client.new!(
      url: "https://example.test",
      api_key: "secret",
      adapter: adapter,
      adapter_opts: []
    )
  end

  defp assert_request(method, url) do
    assert_receive {:request, %Tesla.Env{} = env}
    assert env.method == method
    assert env.url == url
    assert {"api-key", "secret"} in env.headers
    env
  end
end
