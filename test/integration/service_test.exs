defmodule Qdrant.Integration.ServiceTest do
  use Qdrant.IntegrationCase

  test "reads service and single-node cluster endpoints", %{client: client, collection: collection} do
    assert {:ok, %{"title" => title, "version" => version}} = Qdrant.root(client)
    assert title =~ "qdrant"
    assert is_binary(version)

    assert {:ok, healthz} = Qdrant.healthz(client)
    assert healthz in ["healthz check passed", "healthz check passed\n"]

    assert {:ok, livez} = Qdrant.livez(client)
    assert livez in ["healthz check passed", "healthz check passed\n"]

    assert {:ok, readyz} = Qdrant.readyz(client)
    assert readyz in ["all shards are ready", "all shards are ready\n"]

    assert {:ok, %{"result" => _}} = Qdrant.telemetry(client, anonymize: true, details_level: 0)
    assert {:ok, metrics} = Qdrant.metrics(client, anonymize: true)
    assert is_binary(metrics)

    assert {:ok, %{"result" => _}} = Qdrant.cluster_status(client)
    assert {:ok, %{"result" => _}} = Qdrant.collection_cluster_info(client, collection)
  end
end
