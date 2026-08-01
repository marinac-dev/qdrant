defmodule Qdrant.Integration.AliasesTest do
  use Qdrant.IntegrationCase

  test "creates, renames, reads, and deletes a collection alias", %{client: client, collection: collection} do
    alias_name = "alias-#{System.unique_integer([:positive, :monotonic])}"
    renamed_alias = alias_name <> "-renamed"

    on_exit(fn ->
      Qdrant.update_aliases(client, %{actions: [%{delete_alias: %{alias_name: renamed_alias}}]})
    end)

    assert {:ok, %{"result" => true}} =
             Qdrant.update_aliases(client, %{
               actions: [%{create_alias: %{collection_name: collection, alias_name: alias_name}}]
             })

    assert {:ok, %{"result" => %{"aliases" => aliases}}} = Qdrant.get_collection_aliases(client, collection)
    assert Enum.any?(aliases, &(&1["alias_name"] == alias_name))

    assert {:ok, %{"result" => true}} =
             Qdrant.update_aliases(client, %{
               actions: [%{rename_alias: %{old_alias_name: alias_name, new_alias_name: renamed_alias}}]
             })

    assert {:ok, %{"result" => %{"aliases" => aliases}}} = Qdrant.get_collections_aliases(client)
    assert Enum.any?(aliases, &(&1["alias_name"] == renamed_alias))

    assert {:ok, %{"result" => %{"config" => _}}} = Qdrant.get_collection(client, renamed_alias)

    assert {:ok, %{"result" => true}} =
             Qdrant.update_aliases(client, %{actions: [%{delete_alias: %{alias_name: renamed_alias}}]})
  end
end
