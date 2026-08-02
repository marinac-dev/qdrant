defmodule Qdrant.Api.Http.ClusterTest do
  use ExUnit.Case, async: true

  alias Qdrant.Api.Http.Cluster

  test "creates and deletes encoded shard keys with timeout" do
    body = %{shard_key: "north"}

    for {operation, method, suffix} <- [
          {:create_shard_key, :put, "/shards"},
          {:delete_shard_key, :post, "/shards/delete"}
        ] do
      client = client()

      assert {:ok, %{"result" => true}} =
               apply(Cluster, operation, [client, "cities/eu ?#", body, [timeout: 0]])

      assert_receive {:request, env}
      assert env.method == method
      assert env.url == "https://cluster.test/collections/cities%2Feu%20%3F%23#{suffix}?timeout=0"
      assert JSON.decode!(env.body) == %{"shard_key" => "north"}
      assert_header(env, "api-key", "secret")
      assert_header(env, "content-type", "application/json")
    end
  end

  test "covers status, recovery, and encoded collection details contracts" do
    contracts = [
      {:get, "/cluster", &Cluster.cluster_status/1},
      {:post, "/cluster/recover", &Cluster.recover_current_peer/1},
      {:get, "/collections/cities%2Feu%3Fx%3D1/cluster", &Cluster.collection_cluster_info(&1, "cities/eu?x=1")}
    ]

    for {method, path, operation} <- contracts do
      client = client()
      assert {:ok, %{"result" => true}} = operation.(client)
      assert_receive {:request, env}
      assert env.method == method
      assert env.url == "https://cluster.test" <> path
      assert_header(env, "api-key", "secret")

      if method == :post do
        assert JSON.decode!(env.body) == %{}
        assert_header(env, "content-type", "application/json")
      else
        assert env.body == nil
      end
    end
  end

  test "updates an encoded collection cluster with timeout" do
    client = client()
    body = %{drop_replica: %{shard_id: 1, peer_id: 2}}

    assert {:ok, %{"result" => true}} =
             Cluster.update_collection_cluster(client, "cities/%", body, timeout: 12)

    assert_receive {:request, env}
    assert env.method == :post
    assert env.url == "https://cluster.test/collections/cities%2F%25/cluster?timeout=12"

    assert JSON.decode!(env.body) == %{
             "drop_replica" => %{"peer_id" => 2, "shard_id" => 1}
           }
  end

  test "peer removal encodes the peer and retains false while omitting nil" do
    client = client()
    assert {:ok, _} = Cluster.remove_peer(client, "peer/one?", force: false)
    assert_receive {:request, false_env}
    assert false_env.method == :delete
    assert false_env.url == "https://cluster.test/cluster/peer/peer%2Fone%3F?force=false"

    client = client()
    assert {:ok, _} = Cluster.remove_peer(client, "peer/two", force: nil)
    assert_receive {:request, nil_env}
    assert nil_env.url == "https://cluster.test/cluster/peer/peer%2Ftwo"
  end

  test "lists shard keys and collects cluster telemetry" do
    client = client()

    assert {:ok, %{"result" => true}} = Cluster.list_shard_keys(client, "cities/eu")
    assert_receive {:request, shard_keys_env}
    assert shard_keys_env.method == :get
    assert shard_keys_env.url == "https://cluster.test/collections/cities%2Feu/shards"

    client = client()

    assert {:ok, %{"result" => true}} =
             Cluster.cluster_telemetry(client, details_level: 0, timeout: 0)

    assert_receive {:request, telemetry_env}
    assert telemetry_env.method == :get
    assert telemetry_env.url == "https://cluster.test/cluster/telemetry?details_level=0&timeout=0"
  end

  test "returns structured errors from the shared request layer" do
    client = client(%{"status" => "conflict"}, 409, [{"x-request-id", "cluster-1"}])

    assert {:error,
            %Qdrant.Error{
              kind: :http,
              status: 409,
              body: %{"status" => "conflict"},
              method: :get,
              url: "https://cluster.test/cluster",
              request_id: "cluster-1"
            }} = Cluster.cluster_status(client)
  end

  defp client(body \\ %{"result" => true}, status \\ 200, response_headers \\ [{"content-type", "application/json"}]) do
    test_pid = self()

    adapter = fn env ->
      send(test_pid, {:request, env})
      {:ok, %{env | status: status, headers: response_headers, body: body}}
    end

    Qdrant.Client.new!(
      url: "https://cluster.test",
      api_key: "secret",
      adapter: adapter,
      adapter_opts: []
    )
  end

  defp assert_header(env, name, value), do: assert({^name, ^value} = List.keyfind(env.headers, name, 0))
end

defmodule Qdrant.Api.Http.ClusterCompatibilityTest do
  use ExUnit.Case, async: false

  alias Qdrant.Api.Http.Cluster

  test "no-client positional timeout and force forms use compatibility configuration" do
    test_pid = self()

    adapter = fn env ->
      send(test_pid, {:request, env})
      {:ok, %{env | status: 200, headers: [{"content-type", "application/json"}], body: %{"result" => true}}}
    end

    restore_application_env([:url, :adapter, :adapter_opts])
    Application.put_env(:qdrant, :url, "https://compat-cluster.test")
    Application.put_env(:qdrant, :adapter, adapter)
    Application.put_env(:qdrant, :adapter_opts, [])

    assert {:ok, _} = Cluster.create_shard_key("legacy/name", %{shard_key: "one"}, 9)
    assert_receive {:request, create_env}
    assert create_env.url == "https://compat-cluster.test/collections/legacy%2Fname/shards?timeout=9"

    assert {:ok, _} = Cluster.remove_peer("legacy/peer", false)
    assert_receive {:request, remove_env}
    assert remove_env.url == "https://compat-cluster.test/cluster/peer/legacy%2Fpeer?force=false"
  end

  defp restore_application_env(keys) do
    previous = Map.new(keys, &{&1, Application.fetch_env(:qdrant, &1)})

    on_exit(fn ->
      Enum.each(previous, fn
        {key, {:ok, value}} -> Application.put_env(:qdrant, key, value)
        {key, :error} -> Application.delete_env(:qdrant, key)
      end)
    end)
  end
end
