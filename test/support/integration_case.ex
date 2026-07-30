defmodule Qdrant.IntegrationCase do
  use ExUnit.CaseTemplate

  import ExUnit.Assertions
  import ExUnit.Callbacks, only: [on_exit: 1]

  @fixture_path Path.expand("../integration/fixtures/food_search.min.json", __DIR__)
  @fixture @fixture_path |> File.read!() |> Jason.decode!()
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
    collection = "elixir-client-#{System.unique_integer([:positive, :monotonic])}"

    client =
      Qdrant.Client.new!(
        url: System.get_env("QDRANT_URL") || "http://127.0.0.1:6333",
        api_key: System.get_env("QDRANT_API_KEY")
      )

    assert {:ok, _} =
             Qdrant.create_collection(client, collection, %{
               vectors: %{size: @embedding_dimensions, distance: @distance}
             })

    on_exit(fn -> Qdrant.delete_collection(client, collection) end)
    {:ok, client: client, collection: collection}
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
