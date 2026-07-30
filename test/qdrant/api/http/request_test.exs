defmodule Qdrant.Api.Http.RequestTest do
  use ExUnit.Case, async: true

  alias Qdrant.Api.Http.Request

  test "encodes each path segment" do
    cases = %{
      "a b" => "a%20b",
      "a/b" => "a%2Fb",
      "a?x=1" => "a%3Fx%3D1",
      "a%b" => "a%25b",
      "a#b" => "a%23b",
      "café" => "caf%C3%A9",
      "a%20b" => "a%2520b"
    }

    Enum.each(cases, fn {input, expected} -> assert Request.segment(input) == expected end)
  end

  test "omits nil query values but preserves false, zero, and empty strings" do
    assert Request.query("/path", wait: false, offset: 0, value: "", missing: nil, ordering: :strong) ==
             "/path?wait=false&offset=0&value=&ordering=strong"
  end

  test "returns successful envelopes and structured errors" do
    adapter = fn env ->
      case env.url do
        "https://example.test/ok" ->
          {:ok, %{env | status: 200, headers: [{"content-type", "application/json"}], body: %{"result" => true}}}

        "https://example.test/missing" ->
          {:ok, %{env | status: 404, headers: [{"x-request-id", "req-1"}], body: %{"status" => "missing"}}}
      end
    end

    client = Qdrant.Client.new!(url: "https://example.test", adapter: adapter, adapter_opts: [])
    assert {:ok, %{"result" => true}} = Request.request(client, :get, "/ok")

    assert {:error, %Qdrant.Error{kind: :http, status: 404, request_id: "req-1"}} =
             Request.request(client, :get, "/missing")
  end

  test "returns malformed JSON with response context" do
    adapter = fn env ->
      {:ok,
       %{
         env
         | status: 200,
           headers: [{"content-type", "application/json"}, {"x-request-id", "decode-1"}],
           body: "{broken"
       }}
    end

    client = Qdrant.Client.new!(url: "https://example.test", adapter: adapter, adapter_opts: [])

    assert {:error, %Qdrant.Error{kind: :decode, status: 200, body: "{broken", request_id: "decode-1"}} =
             Request.request(client, :get, "/broken")
  end

  test "standardizes representative Qdrant HTTP failures" do
    for status <- [400, 401, 403, 404, 409, 429, 500] do
      adapter = fn env ->
        {:ok,
         %{
           env
           | status: status,
             headers: [{"content-type", "application/json"}],
             body: Jason.encode!(%{status: status})
         }}
      end

      client = Qdrant.Client.new!(url: "https://example.test", adapter: adapter, adapter_opts: [])

      assert {:error, %Qdrant.Error{kind: :http, status: ^status, body: %{"status" => ^status}}} =
               Request.request(client, :get, "/failure")
    end
  end

  test "preserves JSON, text, binary, and empty successful bodies" do
    cases = [
      {[{"content-type", "application/json"}], Jason.encode!(%{result: true}), %{"result" => true}},
      {[{"content-type", "text/plain"}], "metrics 1\n", "metrics 1\n"},
      {[{"content-type", "application/octet-stream"}], <<0, 1, 2>>, <<0, 1, 2>>},
      {[], "", ""}
    ]

    Enum.each(cases, fn {headers, body, expected} ->
      adapter = fn env -> {:ok, %{env | status: 204, headers: headers, body: body}} end
      client = Qdrant.Client.new!(url: "https://example.test", adapter: adapter, adapter_opts: [])
      assert {:ok, ^expected} = Request.request(client, :get, "/response")
    end)
  end
end
