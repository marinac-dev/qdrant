defmodule Qdrant.Integration.SearchTest do
  use Qdrant.IntegrationCase

  test "runs recommendation, discovery, query, grouped, facet, and matrix searches", %{
    client: client,
    collection: collection
  } do
    seed_points(client, collection)
    vector = fixture_query_vector("red_fruit")

    assert {:ok, %{"result" => recommendations}} =
             Qdrant.recommend_points(client, collection, %{positive: [1], negative: [4], limit: 2})

    assert length(recommendations) == 2

    assert {:ok, %{"result" => [batch_recommendations]}} =
             Qdrant.recommend_points_batch(client, collection, %{searches: [%{positive: [1], limit: 2}]})

    assert length(batch_recommendations) == 2

    discovery = %{target: vector, context: [%{positive: 1, negative: 4}], limit: 2}

    assert {:ok, %{"result" => discoveries}} = Qdrant.discover_points(client, collection, discovery)
    assert length(discoveries) == 2

    assert {:ok, %{"result" => [batch_discoveries]}} =
             Qdrant.discover_points_batch(client, collection, %{searches: [discovery]})

    assert length(batch_discoveries) == 2

    assert {:ok, %{"result" => %{"points" => queries}}} =
             Qdrant.query_points(client, collection, %{query: vector, limit: 2, with_payload: true})

    assert Enum.map(queries, & &1["id"]) == [1, 2]

    assert {:ok, %{"result" => [%{"points" => batch_queries}]}} =
             Qdrant.query_points_batch(client, collection, %{searches: [%{query: vector, limit: 2}]})

    assert length(batch_queries) == 2

    group_request = %{vector: vector, group_by: "group", group_size: 1, limit: 2}

    assert {:ok, %{"result" => %{"groups" => groups}}} =
             Qdrant.search_points_groups(client, collection, group_request)

    assert Enum.map(groups, & &1["id"]) |> Enum.sort() == ["green", "red"]

    assert {:ok, %{"result" => %{"groups" => query_groups}}} =
             Qdrant.query_points_groups(client, collection, %{query: vector, group_by: "group", group_size: 1, limit: 2})

    assert length(query_groups) == 2

    assert {:ok, _} =
             Qdrant.create_field_index(client, collection, %{field_name: "category", field_schema: "keyword"},
               wait: true
             )

    assert {:ok, %{"result" => %{"hits" => facets}}} =
             Qdrant.facet_points(client, collection, %{key: "category", limit: 10, exact: true})

    assert Enum.any?(facets, &(&1["value"] == "fruit" and &1["count"] == 2))

    assert {:ok, %{"result" => %{"pairs" => pairs}}} =
             Qdrant.search_matrix_pairs(client, collection, %{sample: 4, limit: 2})

    assert pairs != []

    assert {:ok, %{"result" => %{"ids" => ids, "offsets_row" => rows, "offsets_col" => columns, "scores" => scores}}} =
             Qdrant.search_matrix_offsets(client, collection, %{sample: 4, limit: 2})

    assert length(ids) == 4
    assert length(rows) == length(columns)
    assert length(columns) == length(scores)
  end
end
