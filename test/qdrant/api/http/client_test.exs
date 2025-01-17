defmodule Qdrant.Api.Http.ClientTest do
  use ExUnit.Case
  use Qdrant.Api.Http.Client

  scope "/api/v1"

  import Mox

  setup :set_mox_global
  setup :verify_on_exit!

  describe "base_url/0" do
    setup do
      Application.put_env(:qdrant, :database_url, "http://localhost")
      Application.put_env(:qdrant, :port, "6333")
      :ok
    end

    test "returns the correct base url" do
      assert base_url() == "http://localhost:6333/api/v1"
    end

    test "raises an error when the Qdrant database url is not set" do
      Application.delete_env(:qdrant, :database_url)
      assert_raise RuntimeError, "Qdrant database url is not set", &base_url/0
    end
  end

  describe "Accept system environment variable formats" do
    setup do
      System.put_env("DATABASE_URL", "http://localhost")
      System.put_env("PORT", "6333")
      Application.put_env(:qdrant, :database_url, {:system, "DATABASE_URL"})
      Application.put_env(:qdrant, :port, {:system, "PORT"})
    end

    test "returns the correct base url" do
      assert base_url() == "http://localhost:6333/api/v1"
    end

    test "raises an error when the Qdrant database url is not set" do
      Application.delete_env(:qdrant, :database_url)
      assert_raise RuntimeError, "Qdrant database url is not set", &base_url/0
    end
  end
end
