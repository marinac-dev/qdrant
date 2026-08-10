defmodule Qdrant.IntegrationCase do
  use ExUnit.CaseTemplate

  import ExUnit.Assertions
  import ExUnit.Callbacks, only: [on_exit: 1]

  @fixture_path Path.expand("../integration/fixtures/food_search.min.json", __DIR__)
  @fixture @fixture_path |> File.read!() |> JSON.decode!()
  @embedding_dimensions get_in(@fixture, ["model", "dimensions"])
  @distance get_in(@fixture, ["model", "distance"])
  @fixture_points Map.new(@fixture["points"], &{&1["id"], &1})

  using do
    quote do
      use ExUnit.Case, async: false
      import Qdrant.IntegrationCase

      @moduletag :integration

      setup do
        Qdrant.IntegrationCase.setup_collection()
      end
    end
  end

  def setup_collection do
    collection = unique_name("collection")
    client = client()

    assert {:ok, _} =
             Qdrant.create_collection(client, collection, %{
               vectors: %{size: @embedding_dimensions, distance: @distance}
             })

    on_exit(fn -> delete_collection(client, collection) end)
    {:ok, client: client, collection: collection}
  end

  def client do
    Qdrant.Client.new!(
      url: System.get_env("QDRANT_URL") || "http://127.0.0.1:6333",
      api_key: System.get_env("QDRANT_API_KEY")
    )
  end

  def unique_name(prefix), do: "elixir-client-#{prefix}-#{System.unique_integer([:positive, :monotonic])}"

  def delete_collection(client, collection) do
    case Qdrant.delete_collection(client, collection, wait: true) do
      {:ok, _} -> :ok
      {:error, %Qdrant.Error{status: 404}} -> :ok
      _ -> :ok
    end
  end

  def create_named_collection(client, collection) do
    assert {:ok, _} =
             Qdrant.create_collection(client, collection, %{
               vectors: %{dense: %{size: @embedding_dimensions, distance: @distance}}
             })

    on_exit(fn -> delete_collection(client, collection) end)
    collection
  end

  def shard_id(client, collection) do
    with {:ok, %{"result" => %{"local_shards" => [%{"shard_id" => id} | _]}}} <-
           Qdrant.collection_cluster_info(client, collection) do
      id
    else
      _ -> nil
    end
  end

  def unsupported?(%Qdrant.Error{status: status}) when status in [400, 404, 405, 406, 409, 501], do: true
  def unsupported?(_), do: false

  def assert_supported({:ok, response}), do: response

  def assert_supported({:error, error}) do
    if unsupported?(error) do
      flunk("conditional integration capability is unavailable: #{inspect(error)}")
    else
      flunk("integration request failed: #{inspect(error)}")
    end
  end

  def seed_points(client, collection) do
    points =
      Enum.map(1..4, fn id ->
        point = fixture_point(id)
        %{id: id, vector: point["vector"], payload: point["payload"]}
      end)

    assert {:ok, _} = Qdrant.upsert_points(client, collection, %{points: points}, wait: true)
  end

  def fixture_point(id), do: Map.fetch!(@fixture_points, id)

  def embedding_dimensions, do: @embedding_dimensions

  def distance, do: @distance

  def fixture_vector(id), do: fixture_point(id)["vector"]

  def fixture_payload(id), do: fixture_point(id)["payload"]

  def fixture_query_vector(name), do: get_in(@fixture, ["queries", name, "vector"])

  def assert_vectors_equal(actual, expected) do
    assert length(actual) == length(expected)

    Enum.zip(actual, expected)
    |> Enum.each(fn {actual_value, expected_value} ->
      assert_in_delta actual_value, expected_value, 0.000001
    end)
  end

  def temp_path(name),
    do: Path.join(System.tmp_dir!(), "qdrant-#{System.unique_integer([:positive, :monotonic])}-#{name}")
end
