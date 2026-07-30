defmodule Qdrant.Api.Http.CollectionsTest do
  use ExUnit.Case, async: true

  alias Qdrant.Api.Http.Collections
  alias Qdrant.{Client, Error}

  test "sends collection read requests with encoded path segments" do
    client = client(self())

    operations = [
      {fn -> Collections.list_collections(client) end, "/collections"},
      {fn -> Collections.get_collection(client, "team/blue?") end, "/collections/team%2Fblue%3F"},
      {fn -> Collections.get_collection_details(client, "team/blue?") end, "/collections/team%2Fblue%3F"},
      {fn -> Collections.collection_exists(client, "team/blue?") end, "/collections/team%2Fblue%3F/exists"}
    ]

    Enum.each(operations, fn {operation, path} ->
      assert {:ok, %{"result" => true}} = operation.()
      assert_request(:get, "https://example.test" <> path)
    end)
  end

  test "sends collection writes with JSON bodies and timeout queries" do
    client = client(self())
    create_body = %{vectors: %{size: 4, distance: "Cosine"}}
    update_body = %{optimizers_config: %{deleted_threshold: 0.2}}

    assert {:ok, %{"result" => true}} =
             Collections.create_collection(client, "team/blue", create_body, timeout: nil)

    create_env = assert_request(:put, "https://example.test/collections/team%2Fblue")
    assert_json_request(create_env, create_body)

    assert {:ok, %{"result" => true}} =
             Collections.update_collection(client, "team/blue", update_body, timeout: 0)

    update_env = assert_request(:patch, "https://example.test/collections/team%2Fblue?timeout=0")
    assert_json_request(update_env, update_body)

    assert {:ok, %{"result" => true}} = Collections.delete_collection(client, "team/blue", timeout: nil)
    assert_request(:delete, "https://example.test/collections/team%2Fblue")
  end

  test "returns a structured error for a non-success response" do
    client = client(self(), 409)

    assert {:error,
            %Error{
              kind: :http,
              status: 409,
              body: %{"status" => "conflict"},
              method: :delete,
              url: "https://example.test/collections/team%2Fblue",
              request_id: "req-3a"
            }} = Collections.delete_collection(client, "team/blue")
  end

  defp client(test_pid, status \\ 200) do
    adapter = fn env ->
      send(test_pid, {:request, env})

      body = if status in 200..299, do: %{"result" => true}, else: %{"status" => "conflict"}
      {:ok, %{env | status: status, headers: [{"x-request-id", "req-3a"}], body: body}}
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

  defp assert_json_request(env, body) do
    assert {"content-type", "application/json"} in env.headers
    assert Jason.decode!(env.body) == Jason.decode!(Jason.encode!(body))
  end
end
