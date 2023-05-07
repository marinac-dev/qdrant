defmodule Qdrant.Api.Http.Points do
  @moduledoc """
  Qdrant API Points. Float-point vectors with payload.

  Points are the main data structure in Qdrant.
  Each point is a vector of floats, that is associated with an ID and a payload.
  Qdrant allows to perform search operations on points, and also to store arbitrary JSON payloads with each point.
  Points are stored in collections, and each collection has its own set of vectors.
  """

  use Qdrant.Api.Http.Client
  use Qdrant.Utils.Types

  @doc false
  scope "/collections"

  @type vector :: list(float()) | %{name: String.t(), vector: list(float())}
  @type vectors :: list(vector())
  @type points_batch :: %{batch: %{ids: list(integer() | String.t()), vectors: vectors(), payloads: list(map())}}

  @type point :: %{id: non_neg_integer() | String.t(), vector: list(float()), payload: map()}
  @type points_list :: %{points: list(point())}
  @type upsert_body :: points_batch() | points_list()

  @type delete_body :: %{points: list(integer() | String.t())}

  @type field_condition :: %{
          key: String.t(),
          match: %{value: String.t()} | %{text: String.t()} | %{any: String.t()},
          range: %{gte: float(), lte: float(), gt: float(), lt: float()},
          geo_bounding_box: %{
            top_left: %{lat: float(), lon: float()},
            bottom_right: %{lat: float(), lon: float()}
          },
          geo_radius: %{
            center: %{lat: float(), lon: float()},
            radius: float()
          },
          values_count: %{
            lt: integer(),
            lte: integer(),
            gt: integer(),
            gte: integer()
          }
        }

  @type filter_type :: list(field_condition()) | %{is_empty: map()} | %{has_id: extended_point_id()}
  @type search_params :: %{
          hnsw_ef: integer() | nil,
          exact: boolean(),
          quantization: %{ignore: boolean() | false, rescore: boolean() | false} | nil
        }
  @type search_body :: %{
          vector: vector(),
          filter: %{must: filter_type(), should: filter_type(), must_not: filter_type()} | nil,
          params: search_params(),
          limit: integer()
        }

  @type set_payload_body :: %{payload: map(), points: extended_point_id(), filter: filter_type()}
  @type delete_payload_body :: %{keys: list(String.t()), points: extended_point_id(), filter: filter_type()}

  @type consistency :: non_neg_integer() | :majority | :quorum | :all
  @type with_payload_interface :: boolean() | list(String.t()) | %{include: String.t(), exclude: String.t()}
  @type scroll_body :: %{
          offset: non_neg_integer() | String.t(),
          limit: non_neg_integer(),
          filter: filter_type(),
          with_payload: with_payload_interface(),
          with_vector: boolean() | list(String.t())
        }

  @type search_request :: %{
          vector: vector(),
          filter: filter_type(),
          params: search_params(),
          limit: non_neg_integer(),
          offset: non_neg_integer(),
          with_payload: with_payload_interface(),
          with_vector: boolean() | list(String.t()),
          score_threshold: integer() | nil
        }
  @type search_batch_body :: list(search_request())
  @type recommend_body :: %{
          positive: extended_point_id(),
          negative: extended_point_id(),
          filter: filter_type(),
          params: search_params(),
          limit: non_neg_integer(),
          offset: non_neg_integer(),
          with_payload: with_payload_interface(),
          with_vector: boolean() | list(String.t()),
          score_threshold: non_neg_integer() | nil,
          using: String.t(),
          lookup_from: %{collection: String.t(), vector: String.t()} | nil
        }
  @type recommend_batch_body :: list(recommend_body())

  @doc """
  Perform insert + updates on points. If point with given ID already exists - it will be overwritten. [See more on qdrant](https://qdrant.github.io/qdrant/redoc/index.html#tag/points/operation/upsert_points)

  ## Path parameters

  - collection_name **required** : Name of the collection to update from

  ## Query parameters

  - `wait` *optional* : If true, wait for changes to actually happen

  - `ordering` *optional* : Define ordering guarantees for the operation

  ## Request body schema

  - `batch` **required** : List of points to insert or update
  OR
  - `points` **required** : Point to insert or update
  """
  @spec upsert_points(String.t(), upsert_body(), boolean() | nil, ordering() | nil) :: {:ok, map()} | {:error, any()}
  def upsert_points(collection_name, body, wait \\ false, ordering \\ nil) do
    path =
      "/#{collection_name}/points?"
      |> add_query_param("wait", wait)
      |> add_query_param("ordering", ordering)

    put(path, body)
  end

  @doc """
  Delete points

  ## Path parameters

  - collection_name **required** : Name of the collection to update from

  ## Query parameters

  - `wait` *optional* : If true, wait for changes to actually happen

  - `ordering` *optional* : Define ordering guarantees for the operation

  ## Request body schema

  - `points` **required** : List of points to delete
  """
  @spec delete_points(String.t(), delete_body(), boolean() | nil, ordering() | nil) :: {:ok, map()} | {:error, any()}
  def delete_points(collection_name, body, wait \\ false, ordering \\ nil) do
    path =
      "/#{collection_name}/points/delete?"
      |> add_query_param("wait", wait)
      |> add_query_param("ordering", ordering)

    post(path, body)
  end

  @doc """
  Set payload values for points

  ## Path parameters

  - collection_name **required** : Name of the collection to set from

  ## Query parameters

  - `wait` *optional* : If true, wait for changes to actually happen

  - `ordering` *optional* : Define ordering guarantees for the operation

  ## Request body schema

  - `payload` **required** : Payload to set

  - `points` **required** : Assigns payload to each point in this list

  - `filter` *optional* : Assigns payload to each point that satisfy this filter condition
  """
  @spec set_payload(String.t(), set_payload_body(), boolean() | nil, ordering() | nil) :: {:ok, map()} | {:error, any()}
  def set_payload(collection_name, body, wait \\ false, ordering \\ nil) do
    path =
      "/#{collection_name}/points/payload?"
      |> add_query_param("wait", wait)
      |> add_query_param("ordering", ordering)

    post(path, body)
  end

  @doc """
  Replace full payload of points with new one

  ## Path parameters

  - collection_name **required** : Name of the collection to set from

  ## Query parameters

  - `wait` *optional* : If true, wait for changes to actually happen

  - `ordering` *optional* : Define ordering guarantees for the operation

  ## Request body schema

  - `payload` **required** : Payload to set

  - `points` **required** : Assigns payload to each point in this list

  - `filter` *optional* : Assigns payload to each point that satisfy this filter condition
  """
  @spec overwrite_payload(String.t(), set_payload_body(), boolean() | nil, ordering() | nil) ::
          {:ok, map()} | {:error, any()}
  def overwrite_payload(collection_name, body, wait \\ false, ordering \\ nil) do
    path =
      "/#{collection_name}/points/payload?"
      |> add_query_param("wait", wait)
      |> add_query_param("ordering", ordering)

    put(path, body)
  end

  @doc """
  Delete specified key payload for points

  ## Path parameters

  - collection_name **required** : Name of the collection to delete from

  ## Query parameters

  - `wait` *optional* : If true, wait for changes to actually happen

  - `ordering` *optional* : Define ordering guarantees for the operation

  ## Request body schema

  - `keys` **required** : List of payload keys to remove from payload

  - `points` **required** : Deletes values from each point in this list

  - `filter` *optional* : Deletes values from points that satisfy this filter condition
  """
  @spec delete_payload(String.t(), delete_payload_body(), boolean() | nil, ordering() | nil) ::
          {:ok, map()} | {:error, any()}
  def delete_payload(collection_name, body, wait \\ false, ordering \\ nil) do
    path =
      "/#{collection_name}/points/payload/delete?"
      |> add_query_param("wait", wait)
      |> add_query_param("ordering", ordering)

    post(path, body)
  end

  @doc """
  Remove all payload for specified points

  ## Path parameters

  - collection_name **required** : Name of the collection to clear payload from

  ## Query parameters

  - `wait` *optional* : If true, wait for changes to actually happen

  - `ordering` *optional* : Define ordering guarantees for the operation

  ## Request body schema

  - `points` **required** : List of points to clear payload from
  """
  @spec clear_payload(String.t(), list(integer() | String.t()), boolean() | nil, ordering() | nil) ::
          {:ok, map()} | {:error, any()}
  def clear_payload(collection_name, body, wait \\ false, ordering \\ nil) do
    path =
      "/#{collection_name}/points/payload/clear?"
      |> add_query_param("wait", wait)
      |> add_query_param("ordering", ordering)

    post(path, body)
  end

  @doc """
  Scroll request - paginate over all points which matches given filtering condition

  ## Path parameters

  - collection_name **required** : Name of the collection to retrieve from

  ## Query parameters

  - `consistency` *optional* : Define read consistency guarantees for the operation

  ## Request body schema

  - `offset` *optional* : Start ID to read points from.

  - `limit` *optional* : Page size. Default: 10

  - `filter` *optional* : Look only for points which satisfies this conditions. If not provided - all points.

  - `with_payload` *optional* : Select which payload to return with the response. Default: All

  - `with_vector` *optional* : Options for specifying which vector to include
  """
  @spec scroll_points(String.t(), scroll_body(), consistency() | nil) :: {:ok, map()} | {:error, any()}
  def scroll_points(collection_name, body, consistency \\ nil) do
    path =
      "/#{collection_name}/points/scroll?"
      |> add_query_param("consistency", consistency)

    post(path, body)
  end

  @doc """
  Retrieve closest points based on vector similarity and given filtering conditions

  ## Path parameters

  - collection_name **required** : Name of the collection to search in

  ## Query parameters

  - `consistency` *optional* : Define read consistency guarantees for the operation

  ## Request body schema

  - `vector` **required** : Vector to search for

  - `filter` *optional* : Filter to apply to the search results. Look only for points which satisfies this conditions

  - `params` *optional* : Additional search parameters

  - `limit` **required** : Maximum number of points to return

  - `offset` *optional* : Offset of the first result to return. May be used to paginate results. Note: large offset values may cause performance issues.

  - `with_payload` *optional* : Select which payload to return with the response. Default: None

  - `with_vector` *optional* : Whether to return the point vector with the result?

  - `score_threshold` *optional* : Define a minimal score threshold for the result. If defined, less similar results will not be returned. Score of the returned result might be higher or smaller than the threshold depending on the Distance function used. E.g. for cosine similarity only higher scores will be returned.
  """

  @spec search_points(String.t(), search_body(), integer() | nil) :: {:ok, map()} | {:error, any()}
  def search_points(collection_name, body, consistency \\ nil) do
    path =
      "/#{collection_name}/points/search"
      |> add_query_param("consistency", consistency)

    post(path, body)
  end

  @doc """
  Retrieve by batch the closest points based on vector similarity and given filtering conditions

  ## Path parameters

  - collection_name **required** : Name of the collection to search in

  ## Query parameters

  - `consistency` *optional* : Define read consistency guarantees for the operation

  ## Request body schema

  - `searches` **required** : List of searches to perform
  """
  @spec search_points_batch(String.t(), search_batch_body(), consistency() | nil) :: {:ok, map()} | {:error, any()}
  def search_points_batch(collection_name, body, consistency \\ nil) do
    path =
      "/#{collection_name}/points/search/batch"
      |> add_query_param("consistency", consistency)

    post(path, body)
  end

  @doc """
  Look for the points which are closer to stored positive examples and at the same time further to negative examples.

  ## Path parameters

  - collection_name **required** : Name of the collection to search in

  ## Query parameters

  - `consistency` *optional* : Define read consistency guarantees for the operation

  ## Request body schema

  - `positive` **required** : Look for vectors closest to those

  - `negative` **required** : Look for vectors further from those | Try to avoid vectors like this

  - `filter` *optional* : Look only for points which satisfies this conditions

  - `params` *optional* : Additional search parameters

  - `limit` **required** : Maximum number of points to return

  - `offset` *optional* : Offset of the first result to return. May be used to paginate results. Note: large offset values may cause performance issues.

  - `with_payload` *optional* : Select which payload to return with the response. Default: None

  - `with_vector` *optional* : Whether to return the point vector with the result?

  - `score_threshold` *optional* : Define a minimal score threshold for the result. If defined, less similar results will not be returned. Score of the returned result might be higher or smaller than the threshold depending on the Distance function used. E.g. for cosine similarity only higher scores will be returned.

  - `using` *optional* : Define which vector to use for recommendation, if not specified - try to use default vector

  - `lookup_from` *optional* : The location used to lookup vectors. If not specified - use current collection. Note: the other collection should have the same vector size as the current collection
  """
  @spec recommend_points(String.t(), recommend_body(), consistency() | nil) :: {:ok, map()} | {:error, any()}
  def recommend_points(collection_name, body, consistency \\ nil) do
    path =
      "/#{collection_name}/points/recommend"
      |> add_query_param("consistency", consistency)

    post(path, body)
  end

  @doc """
  Request points based on positive and negative examples.

  ## Path parameters

  - collection_name **required** : Name of the collection to search in

  ## Query parameters

  - `consistency` *optional* : Define read consistency guarantees for the operation

  ## Request body schema

  - `searches` **required** : List of searches to perform
  """
  @spec recommend_points_batch(String.t(), recommend_batch_body(), consistency() | nil) ::
          {:ok, map()} | {:error, any()}
  def recommend_points_batch(collection_name, body, consistency \\ nil) do
    path =
      "/#{collection_name}/points/recommend/batch"
      |> add_query_param("consistency", consistency)

    post(path, body)
  end

  @doc """
  Count points which matches given filtering condition

  ## Path parameters

  - collection_name **required** : Name of the collection to count in

  ## Request body schema

  - `filter` *optional* : Filter to apply to the search results. Look only for points which satisfies this conditions

  - `exact` *optional* : If true, count exact number of points. If false, count approximate number of points faster. Approximate count might be unreliable during the indexing process. Default: true
  """
  @spec count_points(String.t(), %{filter: filter_type(), exact: boolean()}) :: {:ok, map()} | {:error, any()}
  def count_points(collection_name, body) do
    path = "/#{collection_name}/points/count"
    post(path, body)
  end

  # * Private helpers

  defp add_query_param(path, _, nil), do: path
  defp add_query_param(path, key, value), do: path <> "&#{key}=#{value}"
end
