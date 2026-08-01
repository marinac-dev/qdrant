defmodule Qdrant.ClientTest do
  use ExUnit.Case, async: true

  alias Qdrant.Client

  test "builds isolated clients and redacts API keys" do
    adapter = fn env -> {:ok, %{env | status: 200, body: %{}}} end

    first = Client.new!(url: "https://one.example", api_key: "first-secret", adapter: adapter, adapter_opts: [])
    second = Client.new!(url: "https://two.example", api_key: "second-secret", adapter: adapter, adapter_opts: [])

    assert first.interface == :rest
    assert second.interface == :rest
    assert first.url == "https://one.example"
    assert second.url == "https://two.example"
    refute inspect(first) =~ "first-secret"
    refute inspect(second) =~ "second-secret"
  end

  test "normalizes the supported interface and rejects gRPC until implemented" do
    assert {:ok, client} = Client.new(interface: "rest")
    assert client.interface == :rest

    assert {:error, %Qdrant.Error{kind: :configuration, reason: reason}} =
             Client.new(interface: :grpc)

    assert reason =~ "gRPC is unsupported"
  end

  test "uses Finch defaults and passes custom adapters through" do
    assert {:ok, client} = Client.new()
    assert client.adapter == Tesla.Adapter.Finch
    assert client.adapter_opts[:name] == Qdrant.Finch
    assert client.adapter_opts[:receive_timeout] == 30_000
    assert client.adapter_opts[:pool_timeout] == 5_000

    adapter = fn env -> {:ok, env} end
    assert {:ok, custom} = Client.new(adapter: adapter, adapter_opts: [custom: true])
    assert custom.adapter == adapter
    assert custom.adapter_opts == [custom: true]
  end

  test "validates cloud and insecure API key configuration" do
    assert {:error, %Qdrant.Error{kind: :configuration}} = Client.new(url: "https://node.cloud.qdrant.io")

    assert {:error, %Qdrant.Error{kind: :configuration}} =
             Client.new(url: "http://example.com", api_key: "secret")

    assert {:ok, _} = Client.new(url: "http://example.com", api_key: "secret", allow_insecure_api_key: true)
    assert {:ok, _} = Client.new(url: "http://127.0.0.1:6333", api_key: "secret")
  end

  test "normalizes base URLs and paths" do
    client = Client.new!(url: "http://localhost:6333/root/", base_path: "api/v1/")
    assert client.url == "http://localhost:6333/root"
    assert client.base_path == "/api/v1"
  end

  test "dispatches concurrent clients with isolated hosts and credentials" do
    owner = self()

    adapter = fn env ->
      send(owner, {:isolated_request, env.url, Tesla.get_header(env, "api-key")})
      {:ok, %{env | status: 200, headers: [{"content-type", "application/json"}], body: "{}"}}
    end

    first = Client.new!(url: "https://one.example", api_key: "key-one", adapter: adapter, adapter_opts: [])
    second = Client.new!(url: "https://two.example", api_key: "key-two", adapter: adapter, adapter_opts: [])

    tasks = [
      Task.async(fn -> Qdrant.list_collections(first) end),
      Task.async(fn -> Qdrant.list_collections(second) end)
    ]

    assert Enum.map(tasks, &Task.await/1) == [{:ok, %{}}, {:ok, %{}}]
    assert_receive {:isolated_request, "https://one.example/collections", "key-one"}
    assert_receive {:isolated_request, "https://two.example/collections", "key-two"}
  end

  test "rejects malformed URLs and accepts non-cloud HTTPS without a key" do
    for url <- ["localhost:6333", "ftp://localhost", "http://localhost:70000", "http://localhost:6333:6334"] do
      assert {:error, %Qdrant.Error{kind: :configuration}} = Client.new(url: url)
    end

    assert {:ok, _client} = Client.new(url: "https://example.com")
    assert {:error, %Qdrant.Error{kind: :configuration}} = Client.new(url: "https://CLOUD.QDRANT.IO")
  end

  test "redacts authentication response headers in errors" do
    error = %Qdrant.Error{
      kind: :http,
      status: 401,
      headers: [{"Authorization", "Bearer secret"}, {"api-key", "secret"}]
    }

    inspected = inspect(error)
    refute inspected =~ "Bearer secret"
    refute inspected =~ ~s({"api-key", "secret"})
    assert inspected =~ "[REDACTED]"
  end
end
