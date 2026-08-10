defmodule Qdrant.Integration.PointsExtendedTest do
  use Qdrant.IntegrationCase

  test "deletes a named vector from a point", %{client: client} do
    collection = create_named_collection(client, unique_name("vectors"))
    vector = fixture_vector(1)

    assert {:ok, _} =
             Qdrant.upsert_points(client, collection, %{points: [%{id: 1, vector: %{dense: vector}}]}, wait: true)

    assert {:ok, _} =
             Qdrant.create_vector_name(
               client,
               collection,
               "extra",
               %{dense: %{size: embedding_dimensions(), distance: distance()}},
               wait: true
             )

    assert {:ok, _} =
             Qdrant.update_vectors(client, collection, %{points: [%{id: 1, vector: %{extra: vector}}]}, wait: true)

    assert {:ok, _} = Qdrant.delete_vectors(client, collection, %{points: [1], vector: ["extra"]}, wait: true)

    assert {:ok, %{"result" => %{"vector" => vectors}}} = Qdrant.get_point(client, collection, 1, with_vector: true)
    refute Map.has_key?(vectors, "extra")
  end

  test "returns grouped recommendations", %{client: client, collection: collection} do
    seed_points(client, collection)

    assert {:ok, %{"result" => %{"groups" => groups}}} =
             Qdrant.recommend_points_groups(client, collection, %{
               positive: [1],
               group_by: "group",
               group_size: 1,
               limit: 2
             })

    assert groups != []
    assert Enum.all?(groups, &(is_map(&1["id"]) or is_binary(&1["id"])))
    assert Enum.all?(groups, &is_list(&1["hits"]))
  end
end
