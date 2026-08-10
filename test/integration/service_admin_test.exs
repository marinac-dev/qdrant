defmodule Qdrant.Integration.ServiceAdminTest do
  use Qdrant.IntegrationCase

  test "reads and restores lock options", %{client: client} do
    case Qdrant.lock_options(client) do
      {:ok, %{"result" => original}} ->
        on_exit(fn -> Qdrant.set_lock_options(client, original) end)
        assert {:ok, %{"result" => _previous}} = Qdrant.set_lock_options(client, %{write: true})
        assert {:ok, %{"result" => %{"write" => true}}} = Qdrant.lock_options(client)

      {:error, %Qdrant.Error{status: 404}} ->
        :ok
    end
  end
end

defmodule Qdrant.Integration.IssuesTest do
  use Qdrant.IntegrationCase

  test "beta issue endpoints return response envelopes", %{client: client} do
    case Qdrant.get_issues(client) do
      {:ok, %{"result" => _}} ->
        assert {:ok, %{"result" => _}} = Qdrant.clear_issues(client)

      {:error, %Qdrant.Error{status: 404}} ->
        :ok
    end
  end
end
