defmodule Qdrant.Integration.CollectionsExtendedTest do
  use Qdrant.IntegrationCase

  test "creates, uses, deletes named vectors, and reads optimization progress", %{client: client} do
    collection = create_named_collection(client, unique_name("named"))

    assert {:ok, %{"result" => %{"operation_id" => _, "status" => "completed"}}} =
             Qdrant.create_vector_name(
               client,
               collection,
               "extra",
               %{dense: %{size: embedding_dimensions(), distance: distance()}},
               wait: true
             )

    vector = fixture_vector(1)

    point_id = "00000000-0000-4000-8000-000000000001"

    assert {:ok, _} =
             Qdrant.upsert_points(
               client,
               collection,
               %{points: [%{id: point_id, vector: %{dense: vector, extra: vector}}]},
               wait: true
             )

    assert {:ok, %{"result" => %{"vector" => vectors}}} =
             Qdrant.get_point(client, collection, point_id, with_vector: true)

    assert is_map(vectors)
    assert Map.has_key?(vectors, "extra")

    assert {:ok, %{"result" => progress}} = Qdrant.get_optimizations(client, collection)
    assert is_map(progress)

    assert {:ok, %{"result" => %{"operation_id" => _, "status" => "completed"}}} =
             Qdrant.delete_vector_name(client, collection, "extra", wait: true)
  end
end
