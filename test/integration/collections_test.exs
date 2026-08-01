defmodule Qdrant.Integration.CollectionsTest do
  use Qdrant.IntegrationCase

  test "creates, inspects, and deletes a collection", %{client: client, collection: collection} do
    assert {:ok, %{"result" => %{"exists" => true}}} =
             Qdrant.collection_exists(client, collection)

    assert {:ok, %{"result" => %{"config" => %{"params" => %{"vectors" => vectors}}}}} =
             Qdrant.get_collection(client, collection)

    assert vectors["size"] == embedding_dimensions()
    assert vectors["distance"] == distance()

    assert {:ok, %{"result" => true}} = Qdrant.delete_collection(client, collection)
    assert {:ok, %{"result" => %{"exists" => false}}} = Qdrant.collection_exists(client, collection)
  end

  test "creates and deletes a payload index", %{client: client, collection: collection} do
    assert {:ok, _} =
             Qdrant.create_field_index(
               client,
               collection,
               %{field_name: "category", field_schema: "keyword"},
               wait: true
             )

    assert {:ok, %{"result" => %{"payload_schema" => payload_schema}}} =
             Qdrant.get_collection(client, collection)

    assert payload_schema["category"]["data_type"] == "keyword"

    assert {:ok, _} = Qdrant.delete_field_index(client, collection, "category", wait: true)

    assert {:ok, %{"result" => %{"payload_schema" => payload_schema}}} =
             Qdrant.get_collection(client, collection)

    refute Map.has_key?(payload_schema, "category")
  end

  test "lists and updates collection configuration", %{client: client, collection: collection} do
    assert {:ok, %{"result" => %{"collections" => collections}}} = Qdrant.list_collections(client)
    assert Enum.any?(collections, &(&1["name"] == collection))

    assert {:ok, %{"result" => true}} =
             Qdrant.update_collection(client, collection, %{optimizers_config: %{deleted_threshold: 0.3}}, timeout: 5)

    assert {:ok, %{"result" => %{"config" => config}}} = Qdrant.get_collection(client, collection)
    assert config["optimizer_config"]["deleted_threshold"] == 0.3
  end
end
