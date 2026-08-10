defmodule Qdrant.Integration.SnapshotsFullTest do
  use Qdrant.IntegrationCase

  test "runs the full snapshot lifecycle", %{client: client} do
    unique_collection = unique_name("full-source")

    assert {:ok, _} =
             Qdrant.create_collection(client, unique_collection, %{
               vectors: %{size: embedding_dimensions(), distance: distance()}
             })

    seed_points(client, unique_collection)
    on_exit(fn -> delete_collection(client, unique_collection) end)

    assert {:ok, %{"result" => snapshot}} = Qdrant.create_full_snapshot(client, wait: true)
    name = snapshot["name"]
    on_exit(fn -> Qdrant.delete_full_snapshot(client, name, wait: true) end)

    assert {:ok, %{"result" => snapshots}} = Qdrant.list_full_snapshots(client)
    assert Enum.any?(snapshots, &(&1["name"] == name))
    assert {:ok, data} = Qdrant.get_full_snapshot(client, name)
    assert is_binary(data) and byte_size(data) > 0

    destination = temp_path("full.snapshot")
    on_exit(fn -> File.rm(destination) end)
    assert {:ok, ^destination} = Qdrant.download_full_snapshot_to_file(client, name, destination)
    assert File.stat!(destination).size == byte_size(data)

    assert {:ok, %{"result" => true}} = Qdrant.delete_full_snapshot(client, name, wait: true)
  end
end
