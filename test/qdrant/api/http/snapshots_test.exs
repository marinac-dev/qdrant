defmodule Qdrant.Api.Http.SnapshotsTest do
  use ExUnit.Case, async: true

  alias Qdrant.Api.Http.Snapshots
  alias Qdrant.Client

  test "binary uploads use the snapshot field and requested filename" do
    test_pid = self()

    client =
      client(fn env ->
        send(test_pid, {:upload, env})
        ok(env)
      end)

    assert {:ok, %{"result" => true}} =
             Snapshots.recover_from_uploaded_snapshot(client, "collection/name", <<0, 1, 2>>,
               filename: "backup.snapshot",
               wait: false,
               priority: "snapshot",
               checksum: "abc123"
             )

    assert_receive {:upload, env}
    assert URI.parse(env.url).path == "/collections/collection%2Fname/snapshots/upload"

    assert URI.decode_query(URI.parse(env.url).query) == %{
             "checksum" => "abc123",
             "priority" => "snapshot",
             "wait" => "false"
           }

    assert %Tesla.Multipart{parts: [part]} = env.body
    assert part.body == <<0, 1, 2>>
    assert part.dispositions[:name] == "snapshot"
    assert part.dispositions[:filename] == "backup.snapshot"
  end

  test "shard upload includes checksum and streams a file path" do
    path = temp_path("upload.snapshot")
    File.write!(path, "streamed snapshot")
    on_exit(fn -> File.rm(path) end)
    test_pid = self()

    client =
      client(fn env ->
        send(test_pid, {:upload, env})
        ok(env)
      end)

    assert {:ok, _body} =
             Snapshots.recover_shard_from_uploaded_snapshot_file(client, "items", 7, path,
               filename: "shard.snapshot",
               checksum: "sha256",
               wait: true
             )

    assert_receive {:upload, env}
    assert URI.decode_query(URI.parse(env.url).query) == %{"checksum" => "sha256", "wait" => "true"}
    assert %Tesla.Multipart{parts: [part]} = env.body
    assert %File.Stream{} = part.body
    assert Enum.join(part.body) == "streamed snapshot"
    assert part.dispositions[:name] == "snapshot"
    assert part.dispositions[:filename] == "shard.snapshot"
  end

  test "collection, full, and shard deletes pass wait" do
    test_pid = self()

    client =
      client(fn env ->
        send(test_pid, {:delete, env.method, env.url})
        ok(env)
      end)

    assert {:ok, _} = Snapshots.delete_snapshot(client, "a/b", "one?two", wait: false)
    assert {:ok, _} = Snapshots.delete_full_snapshot(client, "full snapshot", wait: true)
    assert {:ok, _} = Snapshots.delete_shard_snapshot(client, "a/b", 3, "shard#one", wait: false)

    assert_receive {:delete, :delete, collection_url}
    assert URI.parse(collection_url).path == "/collections/a%2Fb/snapshots/one%3Ftwo"
    assert URI.decode_query(URI.parse(collection_url).query) == %{"wait" => "false"}

    assert_receive {:delete, :delete, full_url}
    assert URI.parse(full_url).path == "/snapshots/full%20snapshot"
    assert URI.decode_query(URI.parse(full_url).query) == %{"wait" => "true"}

    assert_receive {:delete, :delete, shard_url}
    assert URI.parse(shard_url).path == "/collections/a%2Fb/shards/3/snapshots/shard%23one"
    assert URI.decode_query(URI.parse(shard_url).query) == %{"wait" => "false"}
  end

  test "all snapshot metadata, creation, download, and recovery routes use their Qdrant contracts" do
    test_pid = self()

    client =
      client(fn env ->
        send(test_pid, {:snapshot_contract, env})

        body =
          if String.contains?(env.url, "download.snapshot") do
            "snapshot-bytes"
          else
            Jason.encode!(%{"result" => true})
          end

        content_type = if body == "snapshot-bytes", do: "application/octet-stream", else: "application/json"
        {:ok, %{env | status: 200, headers: [{"content-type", content_type}], body: body}}
      end)

    body = %{location: "file:///snapshot"}

    operations = [
      {fn -> Snapshots.list_snapshots(client, "a/b") end, :get, "/collections/a%2Fb/snapshots", %{}},
      {fn -> Snapshots.create_snapshot(client, "a/b", wait: false) end, :post, "/collections/a%2Fb/snapshots",
       %{"wait" => "false"}},
      {fn -> Snapshots.get_snapshot(client, "a/b", "download.snapshot") end, :get,
       "/collections/a%2Fb/snapshots/download.snapshot", %{}},
      {fn -> Snapshots.recover_from_snapshot(client, "a/b", body, wait: true, priority: "snapshot") end, :put,
       "/collections/a%2Fb/snapshots/recover", %{"priority" => "snapshot", "wait" => "true"}},
      {fn -> Snapshots.list_full_snapshots(client) end, :get, "/snapshots", %{}},
      {fn -> Snapshots.create_full_snapshot(client, wait: false) end, :post, "/snapshots", %{"wait" => "false"}},
      {fn -> Snapshots.get_full_snapshot(client, "download.snapshot") end, :get, "/snapshots/download.snapshot", %{}},
      {fn -> Snapshots.list_shard_snapshots(client, "a/b", "shard/1") end, :get,
       "/collections/a%2Fb/shards/shard%2F1/snapshots", %{}},
      {fn -> Snapshots.create_shard_snapshot(client, "a/b", "shard/1", wait: true) end, :post,
       "/collections/a%2Fb/shards/shard%2F1/snapshots", %{"wait" => "true"}},
      {fn -> Snapshots.get_shard_snapshot(client, "a/b", "shard/1", "download.snapshot") end, :get,
       "/collections/a%2Fb/shards/shard%2F1/snapshots/download.snapshot", %{}},
      {fn -> Snapshots.recover_shard_from_snapshot(client, "a/b", "shard/1", body, priority: "replica") end, :put,
       "/collections/a%2Fb/shards/shard%2F1/snapshots/recover", %{"priority" => "replica"}}
    ]

    Enum.each(operations, fn {call, method, path, query} ->
      assert {:ok, _body} = call.()
      assert_receive {:snapshot_contract, env}
      assert env.method == method
      assert URI.parse(env.url).path == path
      assert decode_query(URI.parse(env.url).query) == query
    end)
  end

  test "in-memory snapshot downloads enforce max_response_bytes" do
    client =
      client(
        fn env ->
          {:ok, %{env | status: 200, headers: [{"content-type", "application/octet-stream"}], body: "four"}}
        end,
        max_response_bytes: 3
      )

    assert {:error, %Qdrant.Error{kind: :response_too_large}} =
             Snapshots.get_full_snapshot(client, "full.snapshot")
  end

  test "download-to-file consumes enumerable response bodies" do
    destination = temp_path("download.snapshot")
    on_exit(fn -> File.rm(destination) end)
    test_pid = self()

    client =
      client(fn env ->
        send(test_pid, {:download, env})

        {:ok,
         %{
           env
           | status: 200,
             headers: [{"content-type", "application/octet-stream"}],
             body: Stream.map(["large ", "snapshot"], & &1)
         }}
      end)

    assert {:ok, ^destination} =
             Snapshots.download_snapshot_to_file(client, "collection", "snapshot", destination)

    assert File.read!(destination) == "large snapshot"
    assert_receive {:download, env}
    assert env.opts[:adapter][:response] == :stream
  end

  test "download-to-file supports binary bodies from custom adapters" do
    destination = temp_path("binary.snapshot")
    on_exit(fn -> File.rm(destination) end)

    client =
      client(fn env ->
        {:ok, %{env | status: 200, headers: [{"content-type", "application/octet-stream"}], body: "snapshot"}}
      end)

    assert {:ok, ^destination} = Snapshots.download_full_snapshot_to_file(client, "full.snapshot", destination)
    assert File.read!(destination) == "snapshot"
  end

  test "download-to-file deletes a partial destination when the stream fails" do
    destination = temp_path("partial.snapshot")
    on_exit(fn -> File.rm(destination) end)

    failing_body =
      Stream.concat([
        ["partial"],
        Stream.map([:failure], fn :failure -> raise "stream failed" end)
      ])

    client =
      client(fn env ->
        {:ok, %{env | status: 200, headers: [{"content-type", "application/octet-stream"}], body: failing_body}}
      end)

    assert {:error, %Qdrant.Error{kind: :file}} =
             Snapshots.download_shard_snapshot_to_file(
               client,
               "collection",
               1,
               "shard.snapshot",
               destination
             )

    refute File.exists?(destination)
  end

  test "download-to-file removes the destination on HTTP and transport failures" do
    http_destination = temp_path("http-failure.snapshot")
    transport_destination = temp_path("transport-failure.snapshot")
    File.write!(http_destination, "stale")
    File.write!(transport_destination, "stale")
    on_exit(fn -> File.rm(http_destination) end)
    on_exit(fn -> File.rm(transport_destination) end)

    http_client =
      client(fn env ->
        {:ok, %{env | status: 404, headers: [{"x-request-id", "request-1"}], body: "missing"}}
      end)

    transport_client = client(fn _env -> {:error, :closed} end)

    assert {:error, %Qdrant.Error{kind: :http, status: 404, request_id: "request-1"}} =
             Snapshots.download_full_snapshot_to_file(http_client, "missing", http_destination)

    assert {:error, %Qdrant.Error{kind: :transport, reason: :closed}} =
             Snapshots.download_full_snapshot_to_file(transport_client, "missing", transport_destination)

    refute File.exists?(http_destination)
    refute File.exists?(transport_destination)
  end

  defp client(adapter, opts \\ []) do
    Client.new!(
      Keyword.merge(
        [url: "https://example.test", adapter: adapter, adapter_opts: []],
        opts
      )
    )
  end

  defp ok(env) do
    {:ok,
     %{
       env
       | status: 200,
         headers: [{"content-type", "application/json"}],
         body: Jason.encode!(%{"result" => true})
     }}
  end

  defp temp_path(name),
    do: Path.join(System.tmp_dir!(), "qdrant-#{System.unique_integer([:positive, :monotonic])}-#{name}")

  defp decode_query(nil), do: %{}
  defp decode_query(query), do: URI.decode_query(query)
end
