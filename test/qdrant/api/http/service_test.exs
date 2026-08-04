defmodule Qdrant.Api.Http.ServiceTest do
  use ExUnit.Case, async: true

  alias Qdrant.Api.Http.Service

  test "covers JSON service routes with isolated client credentials" do
    contracts = [
      {:get, "/", &Service.root/1},
      {:get, "/locks", &Service.lock_options/1},
      {:get, "/issues", &Service.get_issues/1},
      {:delete, "/issues", &Service.clear_issues/1}
    ]

    for {method, path, operation} <- contracts do
      client = client(%{"result" => true})
      assert {:ok, %{"result" => true}} = operation.(client)
      assert_receive {:request, env}
      assert env.method == method
      assert env.url == "https://service.test" <> path
      assert env.body == nil
      assert_header(env, "api-key", "service-secret")
    end
  end

  test "telemetry options retain false and zero and omit nil" do
    client = client(%{"result" => %{}})

    assert {:ok, %{"result" => %{}}} =
             Service.telemetry(client, anonymize: false, details_level: 0)

    assert_receive {:request, env}
    assert env.method == :get
    assert env.url == "https://service.test/telemetry?anonymize=false&details_level=0"

    client = client(%{"result" => %{}})
    assert {:ok, _} = Service.telemetry(client, anonymize: nil, details_level: nil)
    assert_receive {:request, nil_env}
    assert nil_env.url == "https://service.test/telemetry"
  end

  test "telemetry and metrics support per-collection and timeout options" do
    client = client(%{"result" => %{}}, 200, [{"content-type", "application/json"}])

    assert {:ok, _} = Service.telemetry(client, per_collection: false, timeout: 0)
    assert_receive {:request, telemetry_env}
    assert telemetry_env.url == "https://service.test/telemetry?per_collection=false&timeout=0"

    client = client("metric 1\n", 200, [{"content-type", "text/plain"}])
    assert {:ok, "metric 1\n"} = Service.metrics(client, per_collection: true, timeout: 0)
    assert_receive {:request, metrics_env}
    assert metrics_env.url == "https://service.test/metrics?per_collection=true&timeout=0"
  end

  test "metrics options preserve the plain-text response" do
    metrics = "# HELP app_info Qdrant build information\napp_info 1\n"
    client = client(metrics, 200, [{"content-type", "text/plain; version=0.0.4"}])

    assert {:ok, ^metrics} = Service.metrics(client, anonymize: false)
    assert_receive {:request, env}
    assert env.method == :get
    assert env.url == "https://service.test/metrics?anonymize=false"
    assert env.body == nil
    assert_header(env, "api-key", "service-secret")
  end

  test "sets lock options as JSON" do
    client = client(%{"result" => %{"write" => false}})
    body = %{error_message: "maintenance", write: true}

    assert {:ok, %{"result" => %{"write" => false}}} = Service.set_lock_options(client, body)
    assert_receive {:request, env}
    assert env.method == :post
    assert env.url == "https://service.test/locks"
    assert JSON.decode!(env.body) == %{"error_message" => "maintenance", "write" => true}
    assert_header(env, "content-type", "application/json")
  end

  test "health endpoints preserve text, empty, and JSON bodies" do
    cases = [
      {&Service.healthz/1, "healthz check passed", [{"content-type", "text/plain"}], "healthz check passed",
       "/healthz"},
      {&Service.livez/1, "", [{"content-type", "text/plain"}], "", "/livez"},
      {&Service.readyz/1, JSON.encode!(%{"ready" => true}), [{"content-type", "application/json"}], %{"ready" => true},
       "/readyz"}
    ]

    for {operation, response_body, headers, expected, path} <- cases do
      client = client(response_body, 200, headers)
      assert {:ok, ^expected} = operation.(client)
      assert_receive {:request, env}
      assert env.method == :get
      assert env.url == "https://service.test" <> path
    end
  end

  test "returns structured errors from the shared request layer" do
    client = client(%{"status" => "unavailable"}, 503, [{"x-qdrant-request-id", "service-1"}])

    assert {:error,
            %Qdrant.Error{
              kind: :http,
              status: 503,
              body: %{"status" => "unavailable"},
              method: :get,
              url: "https://service.test/healthz",
              request_id: "service-1"
            }} = Service.healthz(client)
  end

  defp client(body, status \\ 200, response_headers \\ [{"content-type", "application/json"}]) do
    test_pid = self()

    adapter = fn env ->
      send(test_pid, {:request, env})
      {:ok, %{env | status: status, headers: response_headers, body: body}}
    end

    Qdrant.Client.new!(
      url: "https://service.test",
      api_key: "service-secret",
      adapter: adapter,
      adapter_opts: []
    )
  end

  defp assert_header(env, name, value), do: assert({^name, ^value} = List.keyfind(env.headers, name, 0))
end

defmodule Qdrant.Api.Http.ServiceCompatibilityTest do
  use ExUnit.Case, async: false

  alias Qdrant.Api.Http.Service

  test "no-client positional telemetry and metrics forms use compatibility configuration" do
    test_pid = self()

    adapter = fn env ->
      send(test_pid, {:request, env})
      body = if String.contains?(env.url, "/metrics"), do: "metric 1\n", else: %{"result" => %{}}
      {:ok, %{env | status: 200, headers: [], body: body}}
    end

    restore_application_env([:url, :adapter, :adapter_opts])
    Application.put_env(:qdrant, :url, "https://compat-service.test")
    Application.put_env(:qdrant, :adapter, adapter)
    Application.put_env(:qdrant, :adapter_opts, [])

    assert {:ok, _} = Service.telemetry(false, 0)
    assert_receive {:request, telemetry_env}
    assert telemetry_env.url == "https://compat-service.test/telemetry?anonymize=false&details_level=0"

    assert {:ok, "metric 1\n"} = Service.metrics(false)
    assert_receive {:request, metrics_env}
    assert metrics_env.url == "https://compat-service.test/metrics?anonymize=false"
  end

  defp restore_application_env(keys) do
    previous = Map.new(keys, &{&1, Application.fetch_env(:qdrant, &1)})

    on_exit(fn ->
      Enum.each(previous, fn
        {key, {:ok, value}} -> Application.put_env(:qdrant, key, value)
        {key, :error} -> Application.delete_env(:qdrant, key)
      end)
    end)
  end
end
