defmodule Qdrant.Api.Http.IndexesTest do
  use ExUnit.Case, async: true

  alias Qdrant.Api.Http.Indexes
  alias Qdrant.{Client, Error}

  test "creates an index with encoded paths, false query values, and a JSON body" do
    client = client(self())
    body = %{field_name: "meta/category", field_schema: "keyword"}

    assert {:ok, %{"result" => true}} =
             Indexes.create_field_index(client, "team/blue", body, wait: false, ordering: nil)

    env = assert_request(:put, "https://example.test/collections/team%2Fblue/index?wait=false")
    assert {"content-type", "application/json"} in env.headers
    assert Jason.decode!(env.body) == %{"field_name" => "meta/category", "field_schema" => "keyword"}
  end

  test "deletes an index with collection and field names encoded as individual segments" do
    client = client(self())

    assert {:ok, %{"result" => true}} =
             Indexes.delete_field_index(client, "team/blue", "meta/category?", wait: nil, ordering: :strong)

    assert_request(
      :delete,
      "https://example.test/collections/team%2Fblue/index/meta%2Fcategory%3F?ordering=strong"
    )
  end

  test "returns a structured error for a non-success response" do
    client = client(self(), 404)

    assert {:error,
            %Error{
              kind: :http,
              status: 404,
              body: %{"status" => "missing field"},
              method: :delete,
              url: "https://example.test/collections/team%2Fblue/index/meta%2Fcategory",
              request_id: "req-index"
            }} = Indexes.delete_field_index(client, "team/blue", "meta/category")
  end

  defp client(test_pid, status \\ 200) do
    adapter = fn env ->
      send(test_pid, {:request, env})

      body = if status in 200..299, do: %{"result" => true}, else: %{"status" => "missing field"}
      {:ok, %{env | status: status, headers: [{"x-request-id", "req-index"}], body: body}}
    end

    Client.new!(
      url: "https://example.test",
      api_key: "secret",
      adapter: adapter,
      adapter_opts: []
    )
  end

  defp assert_request(method, url) do
    assert_receive {:request, %Tesla.Env{} = env}
    assert env.method == method
    assert env.url == url
    assert {"api-key", "secret"} in env.headers
    env
  end
end
