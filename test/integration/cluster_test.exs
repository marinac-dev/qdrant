defmodule Qdrant.Integration.ClusterTest do
  use Qdrant.IntegrationCase

  test "reads shard keys and cluster telemetry", %{client: client, collection: collection} do
    assert {:ok, %{"result" => _}} = Qdrant.list_shard_keys(client, collection)

    case Qdrant.cluster_telemetry(client, details_level: 0) do
      {:ok, %{"result" => _}} ->
        :ok

      {:error, %Qdrant.Error{status: 500, body: body}} ->
        assert body["status"]["error"] =~ "Could not get telemetry from cluster"
    end
  end
end

defmodule Qdrant.Integration.ClusterMutationsTest do
  use Qdrant.IntegrationCase

  test "reserves cluster mutations for the disposable cluster profile" do
    assert System.get_env("QDRANT_CLUSTER_INTEGRATION") in [nil, "true"]
  end
end
