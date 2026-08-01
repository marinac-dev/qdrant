defmodule Qdrant.ConfigTest do
  use ExUnit.Case, async: false

  @app_keys [:url, :database_url, :port, :api_key, :require_api_key, :allow_insecure_api_key, :interface]
  @env_keys ~w(QDRANT_URL QDRANT_DATABASE_URL QDRANT_PORT QDRANT_API_KEY QDRANT_REQUIRE_API_KEY QDRANT_ALLOW_INSECURE_API_KEY)

  setup do
    app = Map.new(@app_keys, &{&1, Application.fetch_env(:qdrant, &1)})
    env = Map.new(@env_keys, &{&1, System.get_env(&1)})

    Enum.each(@app_keys, &Application.delete_env(:qdrant, &1))
    Enum.each(@env_keys, &System.delete_env/1)

    on_exit(fn ->
      Enum.each(app, fn
        {key, {:ok, value}} -> Application.put_env(:qdrant, key, value)
        {key, :error} -> Application.delete_env(:qdrant, key)
      end)

      Enum.each(env, fn
        {key, nil} -> System.delete_env(key)
        {key, value} -> System.put_env(key, value)
      end)
    end)

    :ok
  end

  test "uses the exact URL precedence" do
    System.put_env("QDRANT_DATABASE_URL", "http://env-db")
    System.put_env("QDRANT_PORT", "6004")
    System.put_env("QDRANT_URL", "http://env-url:6003")
    Application.put_env(:qdrant, :database_url, "http://app-db")
    Application.put_env(:qdrant, :port, 6002)
    Application.put_env(:qdrant, :url, "http://app-url:6001")

    assert {:ok, opts} = Qdrant.Config.client_options()
    assert opts[:interface] == :rest
    assert opts[:url] == "http://app-url:6001"

    Application.delete_env(:qdrant, :url)
    assert {:ok, opts} = Qdrant.Config.client_options()
    assert opts[:url] == "http://app-db:6002"

    Application.delete_env(:qdrant, :database_url)
    Application.delete_env(:qdrant, :port)
    assert {:ok, opts} = Qdrant.Config.client_options()
    assert opts[:url] == "http://env-url:6003"

    System.delete_env("QDRANT_URL")
    assert {:ok, opts} = Qdrant.Config.client_options()
    assert opts[:url] == "http://env-db:6004"
  end

  test "rejects malformed ports and booleans" do
    System.put_env("QDRANT_PORT", "6333junk")
    assert {:error, %Qdrant.Error{kind: :configuration}} = Qdrant.Config.client_options()

    System.delete_env("QDRANT_PORT")
    System.put_env("QDRANT_REQUIRE_API_KEY", "yes")
    assert {:error, %Qdrant.Error{kind: :configuration}} = Qdrant.Config.client_options()
  end

  test "rejects gRPC configuration" do
    Application.put_env(:qdrant, :interface, "grpc")
    assert {:error, %Qdrant.Error{reason: reason}} = Qdrant.Config.client_options()
    assert reason =~ "gRPC is unsupported"
  end
end
