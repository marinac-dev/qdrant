defmodule Qdrant.FacadeTest do
  use ExUnit.Case, async: true

  alias Qdrant.Client

  @operations [
    {:list_collections, 0, true, 0},
    {:get_collection, 1, true, 0},
    {:create_collection, 2, true, 1},
    {:update_collection, 2, true, 1},
    {:delete_collection, 1, true, 1},
    {:collection_exists, 1, true, 0},
    {:create_vector_name, 3, true, 3},
    {:delete_vector_name, 2, true, 3},
    {:get_optimizations, 1, true, 1},
    {:get_point, 2, true, 1},
    {:get_points, 2, true, 2},
    {:upsert_points, 2, true, 3},
    {:delete_points, 2, true, 3},
    {:set_payload, 2, true, 3},
    {:overwrite_payload, 2, true, 3},
    {:delete_payload, 2, true, 3},
    {:clear_payload, 2, true, 3},
    {:batch_update_points, 2, true, 3},
    {:scroll_points, 2, true, 1},
    {:search_points, 2, true, 1},
    {:search_points_batch, 2, true, 1},
    {:recommend_points, 2, true, 1},
    {:recommend_points_batch, 2, true, 1},
    {:update_vectors, 2, true, 3},
    {:delete_vectors, 2, true, 3},
    {:search_points_groups, 2, true, 1},
    {:recommend_points_groups, 2, true, 1},
    {:discover_points, 2, true, 1},
    {:discover_points_batch, 2, true, 1},
    {:facet_points, 2, true, 0},
    {:query_points, 2, true, 1},
    {:query_points_batch, 2, true, 1},
    {:query_points_groups, 2, true, 1},
    {:search_matrix_pairs, 2, true, 0},
    {:search_matrix_offsets, 2, true, 0},
    {:count_points, 2, true, 0},
    {:create_field_index, 2, true, 3},
    {:delete_field_index, 2, true, 3},
    {:update_aliases, 1, true, 1},
    {:get_collection_aliases, 1, true, 0},
    {:get_collections_aliases, 0, true, 0},
    {:list_snapshots, 1, true, 0},
    {:create_snapshot, 1, true, 1},
    {:get_snapshot, 2, true, 0},
    {:download_snapshot_to_file, 3, true, 1},
    {:delete_snapshot, 2, true, 1},
    {:recover_from_snapshot, 2, true, 2},
    {:recover_from_uploaded_snapshot, 2, true, 3},
    {:recover_from_uploaded_snapshot_file, 2, true, 1},
    {:list_full_snapshots, 0, true, 0},
    {:create_full_snapshot, 0, true, 1},
    {:get_full_snapshot, 1, true, 0},
    {:download_full_snapshot_to_file, 2, true, 1},
    {:delete_full_snapshot, 1, true, 1},
    {:list_shard_snapshots, 2, true, 0},
    {:create_shard_snapshot, 2, true, 1},
    {:get_shard_snapshot, 3, true, 0},
    {:stream_shard_snapshot, 2, false, 0},
    {:download_shard_snapshot_to_file, 4, true, 1},
    {:delete_shard_snapshot, 3, true, 1},
    {:recover_shard_from_snapshot, 3, true, 2},
    {:recover_shard_from_uploaded_snapshot, 3, true, 3},
    {:recover_shard_from_uploaded_snapshot_file, 3, true, 1},
    {:create_shard_key, 2, true, 1},
    {:delete_shard_key, 2, true, 1},
    {:list_shard_keys, 1, false, 0},
    {:cluster_status, 0, false, 0},
    {:recover_current_peer, 0, false, 0},
    {:remove_peer, 1, true, 1},
    {:collection_cluster_info, 1, false, 0},
    {:update_collection_cluster, 2, true, 1},
    {:cluster_telemetry, 0, true, 1},
    {:root, 0, false, 0},
    {:telemetry, 0, true, 4},
    {:metrics, 0, true, 3},
    {:lock_options, 0, false, 0},
    {:set_lock_options, 1, false, 0},
    {:healthz, 0, false, 0},
    {:livez, 0, false, 0},
    {:readyz, 0, false, 0},
    {:get_issues, 0, false, 0},
    {:clear_issues, 0, false, 0}
  ]

  @expected_exports (Enum.flat_map(@operations, fn {name, required, opts?, optional} ->
                       client_arities = if opts?, do: [required + 1, required + 2], else: [required + 1]
                       compatibility_arities = Enum.to_list(required..(required + optional))
                       Enum.map(Enum.uniq(client_arities ++ compatibility_arities), &{name, &1})
                     end) ++
                       [
                         default_client: 0,
                         default_client!: 0,
                         collection_info: 1,
                         collection_info: 2,
                         collection_info: 3,
                         get_collection_details: 1,
                         get_collection_details: 2,
                         get_collection_details: 3,
                         upsert_point: 2,
                         upsert_point: 3,
                         upsert_point: 4
                       ])
                    |> MapSet.new()

  test "exports every facade form and attaches a spec to every arity" do
    exports = Qdrant.__info__(:functions) |> MapSet.new()
    assert exports == @expected_exports

    assert {:ok, specs} = Code.Typespec.fetch_specs(Qdrant)
    spec_exports = specs |> Enum.map(&elem(&1, 0)) |> MapSet.new()
    assert MapSet.subset?(exports, spec_exports)
  end

  test "client-first facade calls fixed endpoint families and preserves envelopes" do
    envelope = %{"result" => %{"preserved" => true}, "status" => "ok", "time" => 0.001}
    client = recording_client(self(), envelope)
    body = %{marker: true}

    operations = [
      {fn -> Qdrant.list_collections(client) end, :get, "/collections", %{}},
      {fn -> Qdrant.upsert_points(client, "items/a", body, wait: false, ordering: :strong) end, :put,
       "/collections/items%2Fa/points", %{"ordering" => "strong", "wait" => "false"}},
      {fn -> Qdrant.create_field_index(client, "items", body, wait: false) end, :put, "/collections/items/index",
       %{"wait" => "false"}},
      {fn -> Qdrant.update_aliases(client, body, timeout: 0) end, :post, "/collections/aliases", %{"timeout" => "0"}},
      {fn -> Qdrant.delete_snapshot(client, "items", "daily/one", wait: false) end, :delete,
       "/collections/items/snapshots/daily%2Fone", %{"wait" => "false"}},
      {fn -> Qdrant.remove_peer(client, "peer/one", force: false) end, :delete, "/cluster/peer/peer%2Fone",
       %{"force" => "false"}},
      {fn -> Qdrant.root(client) end, :get, "/", %{}}
    ]

    Enum.each(operations, fn {call, method, path, query} ->
      assert {:ok, ^envelope} = call.()
      assert_receive {:request, env}
      assert env.method == method
      assert URI.parse(env.url).path == path
      assert decode_query(URI.parse(env.url).query) == query
    end)
  end

  test "compatibility aliases delegate and expose migration metadata" do
    envelope = %{"result" => true, "status" => "ok"}
    client = recording_client(self(), envelope)
    collection_info = Function.capture(Qdrant, :collection_info, 2)
    get_collection_details = Function.capture(Qdrant, :get_collection_details, 2)
    upsert_point = Function.capture(Qdrant, :upsert_point, 3)

    assert {:ok, ^envelope} = collection_info.(client, "items")
    assert_receive {:request, collection_env}
    assert URI.parse(collection_env.url).path == "/collections/items"

    assert {:ok, ^envelope} = get_collection_details.(client, "items")
    assert_receive {:request, details_env}
    assert URI.parse(details_env.url).path == "/collections/items"

    assert {:ok, ^envelope} = upsert_point.(client, "items", %{points: []})
    assert_receive {:request, upsert_env}
    assert upsert_env.method == :put
    assert URI.parse(upsert_env.url).path == "/collections/items/points"

    assert {:docs_v1, _, _, _, _, _, docs} = Code.fetch_docs(Qdrant)

    for {{:function, name, _arity}, _, _, _, metadata} <- docs,
        name in [:collection_info, :get_collection_details, :upsert_point] do
      assert is_binary(metadata[:deprecated])
      assert metadata[:deprecated] =~ canonical_name(name)
    end
  end

  defp recording_client(owner, envelope) do
    adapter = fn env ->
      send(owner, {:request, env})
      {:ok, %{env | status: 200, headers: [{"content-type", "application/json"}], body: envelope}}
    end

    Client.new!(url: "https://facade.test", adapter: adapter, adapter_opts: [])
  end

  defp decode_query(nil), do: %{}
  defp decode_query(query), do: URI.decode_query(query)

  defp canonical_name(:upsert_point), do: "upsert_points"
  defp canonical_name(_name), do: "get_collection"
end

defmodule Qdrant.DefaultFacadeTest do
  use ExUnit.Case, async: false

  alias Qdrant.{Client, Error}

  @config_keys [
    :url,
    :api_key,
    :adapter,
    :adapter_opts,
    :interface,
    :require_api_key,
    :allow_insecure_api_key
  ]

  setup do
    previous = Map.new(@config_keys, &{&1, Application.fetch_env(:qdrant, &1)})

    on_exit(fn ->
      Enum.each(previous, fn
        {key, {:ok, value}} -> Application.put_env(:qdrant, key, value)
        {key, :error} -> Application.delete_env(:qdrant, key)
      end)
    end)

    :ok
  end

  test "default facade forms use default_client and invalid configuration raises in the bang form" do
    owner = self()

    adapter = fn env ->
      send(owner, {:request, env})
      body = %{"result" => %{"collections" => []}, "status" => "ok", "time" => 0.0}
      {:ok, %{env | status: 200, headers: [{"content-type", "application/json"}], body: body}}
    end

    Application.put_env(:qdrant, :url, "https://default-facade.test")
    Application.put_env(:qdrant, :api_key, nil)
    Application.put_env(:qdrant, :adapter, adapter)
    Application.put_env(:qdrant, :adapter_opts, [])
    Application.put_env(:qdrant, :interface, :rest)
    Application.put_env(:qdrant, :require_api_key, false)
    Application.put_env(:qdrant, :allow_insecure_api_key, false)

    assert {:ok, %Client{interface: :rest, url: "https://default-facade.test"}} = Qdrant.default_client()
    assert %Client{interface: :rest, url: "https://default-facade.test"} = Qdrant.default_client!()

    assert {:ok, response} = Qdrant.list_collections()
    assert response == %{"result" => %{"collections" => []}, "status" => "ok", "time" => 0.0}

    assert_receive {:request, env}
    assert env.url == "https://default-facade.test/collections"

    Application.put_env(:qdrant, :url, "not-a-url")
    assert {:error, %Error{kind: :configuration}} = Qdrant.default_client()
    assert_raise Error, fn -> Qdrant.default_client!() end
  end
end
