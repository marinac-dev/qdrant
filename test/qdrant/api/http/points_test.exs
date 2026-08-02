defmodule Qdrant.Api.Http.PointsTest do
  use ExUnit.Case, async: false

  alias Qdrant.Api.Http.Points
  alias Qdrant.Client

  @collection "team/a ?%#"
  @encoded_collection "team%2Fa%20%3F%25%23"

  test "all 27 operations preserve their wire contracts" do
    client = recording_client(self())
    body = %{marker: "wire"}
    batch = %{searches: [%{marker: "wire"}]}
    write_opts = [wait: false, ordering: :strong, timeout: 99]
    search_opts = [consistency: :quorum, timeout: 17, wait: true]

    operations = [
      {fn -> Points.get_point(client, @collection, "id/a?b", consistency: :all, timeout: 17) end, :get,
       "/collections/#{@encoded_collection}/points/id%2Fa%3Fb", nil, %{"consistency" => "all"}},
      {fn -> Points.get_points(client, @collection, body, consistency: 2, timeout: 17) end, :post,
       "/collections/#{@encoded_collection}/points", body, %{"consistency" => "2", "timeout" => "17"}},
      {fn -> Points.upsert_points(client, @collection, body, write_opts) end, :put,
       "/collections/#{@encoded_collection}/points", body,
       %{"ordering" => "strong", "timeout" => "99", "wait" => "false"}},
      {fn -> Points.delete_points(client, @collection, body, write_opts) end, :post,
       "/collections/#{@encoded_collection}/points/delete", body,
       %{"ordering" => "strong", "timeout" => "99", "wait" => "false"}},
      {fn -> Points.set_payload(client, @collection, body, write_opts) end, :post,
       "/collections/#{@encoded_collection}/points/payload", body,
       %{"ordering" => "strong", "timeout" => "99", "wait" => "false"}},
      {fn -> Points.overwrite_payload(client, @collection, body, write_opts) end, :put,
       "/collections/#{@encoded_collection}/points/payload", body,
       %{"ordering" => "strong", "timeout" => "99", "wait" => "false"}},
      {fn -> Points.delete_payload(client, @collection, body, write_opts) end, :post,
       "/collections/#{@encoded_collection}/points/payload/delete", body,
       %{"ordering" => "strong", "timeout" => "99", "wait" => "false"}},
      {fn -> Points.clear_payload(client, @collection, %{points: [1, "two"]}, write_opts) end, :post,
       "/collections/#{@encoded_collection}/points/payload/clear", %{points: [1, "two"]},
       %{"ordering" => "strong", "timeout" => "99", "wait" => "false"}},
      {fn -> Points.batch_update_points(client, @collection, body, write_opts) end, :post,
       "/collections/#{@encoded_collection}/points/batch", body,
       %{"ordering" => "strong", "timeout" => "99", "wait" => "false"}},
      {fn -> Points.scroll_points(client, @collection, body, search_opts) end, :post,
       "/collections/#{@encoded_collection}/points/scroll", body, %{"consistency" => "quorum", "timeout" => "17"}},
      {fn -> Points.search_points(client, @collection, body, search_opts) end, :post,
       "/collections/#{@encoded_collection}/points/search", body, %{"consistency" => "quorum", "timeout" => "17"}},
      {fn -> Points.search_points_batch(client, @collection, batch, search_opts) end, :post,
       "/collections/#{@encoded_collection}/points/search/batch", batch,
       %{"consistency" => "quorum", "timeout" => "17"}},
      {fn -> Points.recommend_points(client, @collection, body, search_opts) end, :post,
       "/collections/#{@encoded_collection}/points/recommend", body, %{"consistency" => "quorum", "timeout" => "17"}},
      {fn -> Points.recommend_points_batch(client, @collection, batch, search_opts) end, :post,
       "/collections/#{@encoded_collection}/points/recommend/batch", batch,
       %{"consistency" => "quorum", "timeout" => "17"}},
      {fn -> Points.update_vectors(client, @collection, body, write_opts) end, :put,
       "/collections/#{@encoded_collection}/points/vectors", body,
       %{"ordering" => "strong", "timeout" => "99", "wait" => "false"}},
      {fn -> Points.delete_vectors(client, @collection, body, write_opts) end, :post,
       "/collections/#{@encoded_collection}/points/vectors/delete", body,
       %{"ordering" => "strong", "timeout" => "99", "wait" => "false"}},
      {fn -> Points.search_points_groups(client, @collection, body, search_opts) end, :post,
       "/collections/#{@encoded_collection}/points/search/groups", body,
       %{"consistency" => "quorum", "timeout" => "17"}},
      {fn -> Points.recommend_points_groups(client, @collection, body, search_opts) end, :post,
       "/collections/#{@encoded_collection}/points/recommend/groups", body,
       %{"consistency" => "quorum", "timeout" => "17"}},
      {fn -> Points.discover_points(client, @collection, body, search_opts) end, :post,
       "/collections/#{@encoded_collection}/points/discover", body, %{"consistency" => "quorum", "timeout" => "17"}},
      {fn -> Points.discover_points_batch(client, @collection, batch, search_opts) end, :post,
       "/collections/#{@encoded_collection}/points/discover/batch", batch,
       %{"consistency" => "quorum", "timeout" => "17"}},
      {fn -> Points.facet_points(client, @collection, body, search_opts) end, :post,
       "/collections/#{@encoded_collection}/facet", body, %{"consistency" => "quorum", "timeout" => "17"}},
      {fn -> Points.query_points(client, @collection, body, search_opts) end, :post,
       "/collections/#{@encoded_collection}/points/query", body, %{"consistency" => "quorum", "timeout" => "17"}},
      {fn -> Points.query_points_batch(client, @collection, batch, search_opts) end, :post,
       "/collections/#{@encoded_collection}/points/query/batch", batch,
       %{"consistency" => "quorum", "timeout" => "17"}},
      {fn -> Points.query_points_groups(client, @collection, body, search_opts) end, :post,
       "/collections/#{@encoded_collection}/points/query/groups", body,
       %{"consistency" => "quorum", "timeout" => "17"}},
      {fn -> Points.search_matrix_pairs(client, @collection, body, search_opts) end, :post,
       "/collections/#{@encoded_collection}/points/search/matrix/pairs", body,
       %{"consistency" => "quorum", "timeout" => "17"}},
      {fn -> Points.search_matrix_offsets(client, @collection, body, search_opts) end, :post,
       "/collections/#{@encoded_collection}/points/search/matrix/offsets", body,
       %{"consistency" => "quorum", "timeout" => "17"}},
      {fn -> Points.count_points(client, @collection, body, timeout: 17, consistency: :all) end, :post,
       "/collections/#{@encoded_collection}/points/count", body, %{"timeout" => "17"}}
    ]

    assert length(operations) == 27

    Enum.each(operations, fn {call, method, path, expected_body, expected_query} ->
      assert {:ok, %{"result" => true}} = call.()
      assert_receive {:request, env}
      assert env.method == method

      uri = URI.parse(env.url)
      assert uri.path == path
      assert decode_query(uri.query) == expected_query

      if expected_body do
        assert JSON.decode!(env.body) == stringify_keys(expected_body)
        assert {"content-type", "application/json"} in env.headers
      else
        assert env.body in [nil, ""]
      end
    end)
  end

  test "clear_payload sends a filter selector map as JSON" do
    client = recording_client(self())
    selector = %{filter: %{must: [%{key: "city", match: %{value: "Berlin"}}]}}

    assert {:ok, _} = Points.clear_payload(client, "places", selector)
    assert_receive {:request, env}
    assert JSON.decode!(env.body) == stringify_keys(selector)
  end

  test "no-client positional wrappers build a configured client and preserve options" do
    owner = self()
    adapter = success_adapter(owner)
    restore = preserve_application_env([:url, :adapter, :adapter_opts])
    on_exit(restore)

    Application.put_env(:qdrant, :url, "https://legacy.example")
    Application.put_env(:qdrant, :adapter, adapter)
    Application.put_env(:qdrant, :adapter_opts, [])

    assert {:ok, _} = Points.get_point("legacy collection", 7, :majority)
    assert_receive {:request, first}
    assert URI.parse(first.url).path == "/collections/legacy%20collection/points/7"
    assert decode_query(URI.parse(first.url).query) == %{"consistency" => "majority"}

    assert {:ok, _} = Points.upsert_points("legacy collection", %{points: []}, true, :medium)
    assert_receive {:request, second}
    assert decode_query(URI.parse(second.url).query) == %{"ordering" => "medium", "wait" => "true"}
  end

  test "returns shared structured errors" do
    adapter = fn env ->
      {:ok,
       %{
         env
         | status: 422,
           headers: [{"content-type", "application/json"}, {"x-request-id", "points-1"}],
           body: JSON.encode!(%{status: %{error: "bad request"}})
       }}
    end

    client = Client.new!(url: "https://error.example", adapter: adapter, adapter_opts: [])

    assert {:error,
            %Qdrant.Error{
              kind: :http,
              status: 422,
              method: :post,
              url: "https://error.example/collections/bad/points/search",
              request_id: "points-1",
              body: %{"status" => %{"error" => "bad request"}}
            }} = Points.search_points(client, "bad", %{vector: [1.0], limit: 1})
  end

  defp recording_client(owner) do
    Client.new!(url: "https://points.example", adapter: success_adapter(owner), adapter_opts: [])
  end

  defp success_adapter(owner) do
    fn env ->
      send(owner, {:request, env})

      {:ok,
       %{
         env
         | status: 200,
           headers: [{"content-type", "application/json"}],
           body: JSON.encode!(%{result: true})
       }}
    end
  end

  defp decode_query(nil), do: %{}
  defp decode_query(query), do: URI.decode_query(query)

  defp stringify_keys(value) do
    value
    |> JSON.encode!()
    |> JSON.decode!()
  end

  defp preserve_application_env(keys) do
    previous = Map.new(keys, &{&1, Application.fetch_env(:qdrant, &1)})

    fn ->
      Enum.each(previous, fn
        {key, {:ok, value}} -> Application.put_env(:qdrant, key, value)
        {key, :error} -> Application.delete_env(:qdrant, key)
      end)
    end
  end
end
