defmodule Qdrant.Integration.SnapshotsShardTest do
  use Qdrant.IntegrationCase

  setup %{client: client, collection: collection} do
    case shard_id(client, collection) do
      nil -> {:skip, "Qdrant did not advertise a local shard"}
      _shard_id -> :ok
    end
  end

  test "runs the shard snapshot lifecycle when exposed", %{client: client, collection: collection} do
    case shard_id(client, collection) do
      nil -> raise "shard capability changed after setup"
      shard_id -> shard_snapshot_lifecycle(client, collection, shard_id)
    end
  end

  defp shard_snapshot_lifecycle(client, collection, shard_id) do
    assert {:ok, %{"result" => snapshot}} = Qdrant.create_shard_snapshot(client, collection, shard_id, wait: true)
    name = snapshot["name"]
    on_exit(fn -> Qdrant.delete_shard_snapshot(client, collection, shard_id, name, wait: true) end)

    assert {:ok, %{"result" => snapshots}} = Qdrant.list_shard_snapshots(client, collection, shard_id)
    assert Enum.any?(snapshots, &(&1["name"] == name))
    assert {:ok, data} = Qdrant.get_shard_snapshot(client, collection, shard_id, name)
    assert is_binary(data) and byte_size(data) > 0

    destination = temp_path("shard.snapshot")
    on_exit(fn -> File.rm(destination) end)
    assert {:ok, ^destination} = Qdrant.download_shard_snapshot_to_file(client, collection, shard_id, name, destination)
    assert File.stat!(destination).size == byte_size(data)
    assert {:ok, stream_data} = Qdrant.stream_shard_snapshot(client, collection, shard_id)
    assert is_binary(stream_data) and byte_size(stream_data) > 0
    assert {:ok, %{"result" => true}} = Qdrant.delete_shard_snapshot(client, collection, shard_id, name, wait: true)
  end
end
