defmodule Qdrant.Integration.SnapshotsTest do
  use Qdrant.IntegrationCase

  test "creates, lists, and deletes a snapshot", %{client: client, collection: collection} do
    assert {:ok, %{"result" => snapshot}} = Qdrant.create_snapshot(client, collection, wait: true)
    assert {:ok, %{"result" => snapshots}} = Qdrant.list_snapshots(client, collection)
    assert Enum.any?(snapshots, &(&1["name"] == snapshot["name"]))

    assert {:ok, _} = Qdrant.delete_snapshot(client, collection, snapshot["name"], wait: true)

    assert {:ok, %{"result" => snapshots}} = Qdrant.list_snapshots(client, collection)
    refute Enum.any?(snapshots, &(&1["name"] == snapshot["name"]))
  end

  test "downloads a collection snapshot to memory and a file", %{client: client, collection: collection} do
    seed_points(client, collection)

    assert {:ok, %{"result" => snapshot}} = Qdrant.create_snapshot(client, collection, wait: true)
    snapshot_name = snapshot["name"]
    destination = temp_path("collection.snapshot")
    on_exit(fn -> File.rm(destination) end)

    assert {:ok, snapshot_data} = Qdrant.get_snapshot(client, collection, snapshot_name)
    assert is_binary(snapshot_data)
    assert byte_size(snapshot_data) > 0

    assert {:ok, ^destination} = Qdrant.download_snapshot_to_file(client, collection, snapshot_name, destination)
    assert File.stat!(destination).size == byte_size(snapshot_data)
  end
end
