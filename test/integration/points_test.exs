defmodule Qdrant.Integration.PointsTest do
  use Qdrant.IntegrationCase

  test "persists, searches, updates, and deletes points", %{client: client, collection: collection} do
    vector = fixture_vector(1)

    assert {:ok, _} =
             Qdrant.upsert_points(
               client,
               collection,
               %{
                 points: [
                   %{id: 1, vector: vector, payload: %{category: "one"}},
                   %{id: 2, vector: fixture_vector(2)}
                 ]
               },
               wait: true
             )

    assert {:ok, %{"result" => result}} =
             Qdrant.get_points(client, collection, %{ids: [1, 2], with_payload: true})

    points = Map.new(result, &{&1["id"], &1})
    assert Map.keys(points) |> Enum.sort() == [1, 2]
    assert points[1]["payload"] == %{"category" => "one"}

    assert {:ok, %{"result" => search_result}} =
             Qdrant.search_points(client, collection, %{vector: vector, limit: 2})

    assert Enum.map(search_result, & &1["id"]) |> MapSet.new() == MapSet.new([1, 2])

    assert {:ok, %{"result" => [batch_result]}} =
             Qdrant.search_points_batch(client, collection, %{searches: [%{vector: vector, limit: 2}]})

    assert Enum.map(batch_result, & &1["id"]) |> MapSet.new() == MapSet.new([1, 2])

    assert {:ok, _} =
             Qdrant.set_payload(client, collection, %{payload: %{tag: "set"}, points: [1]}, wait: true)

    assert {:ok, %{"result" => %{"payload" => payload}}} =
             Qdrant.get_point(client, collection, 1, with_payload: true)

    assert payload == %{"category" => "one", "tag" => "set"}

    assert {:ok, _} = Qdrant.clear_payload(client, collection, %{points: [1]}, wait: true)
    assert {:ok, %{"result" => %{"payload" => %{}}}} = Qdrant.get_point(client, collection, 1, with_payload: true)

    assert {:ok, _} = Qdrant.delete_points(client, collection, %{points: [1, 2]}, wait: true)
    assert {:ok, %{"result" => []}} = Qdrant.get_points(client, collection, %{ids: [1, 2]})
  end

  test "scrolls, counts, and mutates points", %{client: client, collection: collection} do
    seed_points(client, collection)

    assert {:ok, %{"result" => %{"points" => points, "next_page_offset" => next_page_offset}}} =
             Qdrant.scroll_points(client, collection, %{limit: 2, with_payload: true, with_vector: true})

    assert Enum.map(points, & &1["id"]) == [1, 2]
    assert next_page_offset == 3

    assert {:ok, %{"result" => %{"count" => 2}}} =
             Qdrant.count_points(client, collection, %{filter: %{must: [%{key: "category", match: %{value: "fruit"}}]}})

    assert {:ok, _} =
             Qdrant.overwrite_payload(client, collection, %{payload: %{category: "fruit", replaced: true}, points: [1]},
               wait: true
             )

    assert {:ok, %{"result" => %{"payload" => %{"category" => "fruit", "replaced" => true}}}} =
             Qdrant.get_point(client, collection, 1, with_payload: true)

    assert {:ok, _} = Qdrant.delete_payload(client, collection, %{keys: ["replaced"], points: [1]}, wait: true)

    assert {:ok, %{"result" => %{"payload" => %{"category" => "fruit"}}}} =
             Qdrant.get_point(client, collection, 1, with_payload: true)

    updated_vector = Enum.map(fixture_vector(2), &(&1 * 2.0))

    assert {:ok, _} =
             Qdrant.update_vectors(client, collection, %{points: [%{id: 1, vector: updated_vector}]}, wait: true)

    assert {:ok, %{"result" => %{"vector" => returned_vector}}} =
             Qdrant.get_point(client, collection, 1, with_vector: true)

    assert_vectors_equal(returned_vector, fixture_vector(2))
  end

  test "applies a batch update with upsert and payload operations", %{client: client, collection: collection} do
    batch = %{
      operations: [
        %{upsert: %{points: [%{id: 5, vector: fixture_vector(5), payload: fixture_payload(5)}]}},
        %{set_payload: %{payload: %{processed: true}, points: [5]}}
      ]
    }

    assert {:ok, %{"result" => results}} = Qdrant.batch_update_points(client, collection, batch, wait: true)
    assert Enum.map(results, & &1["status"]) == ["completed", "completed"]

    assert {:ok, %{"result" => %{"payload" => payload}}} =
             Qdrant.get_point(client, collection, 5, with_payload: true)

    assert payload == %{"category" => "batch", "processed" => true}
  end
end
