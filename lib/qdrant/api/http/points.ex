defmodule Qdrant.Api.Http.Points do
  @moduledoc """
  Qdrant API Points. Float-point vectors with payload.

  Points are the main data structure in Qdrant.
  Each point is a vector of floats, that is associated with an ID and a payload.
  Qdrant allows to perform search operations on points, and also to store arbitrary JSON payloads with each point.
  Points are stored in collections, and each collection has its own set of vectors.
  """

  use Qdrant.Utils.Types

  alias Qdrant.Api.Http.Client

  defp client, do: Client.client()

  @type vectors :: list(vector())
  @type points_batch :: %{
          batch: %{ids: list(non_neg_integer() | String.t()), vectors: vectors(), payloads: list(map())}
        }

  @type get_points_body :: %{
          ids: list(non_neg_integer() | String.t()),
          with_payload: with_payload_interface(),
          with_vector: boolean() | list(String.t())
        }

  @type points_list :: %{points: list(point())}
  @type upsert_body :: points_batch() | points_list()

  @type delete_body ::
          %{points: list(non_neg_integer() | String.t())}
          | %{filter: %{must: filter_type(), should: filter_type(), must_not: filter_type()}}

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
            lt: non_neg_integer(),
            lte: non_neg_integer(),
            gt: non_neg_integer(),
            gte: non_neg_integer()
          }
        }

  @type filter_type :: list(field_condition()) | %{is_empty: map()} | %{has_id: extended_point_id()}

  @type filter ::
          %{
            must: filter_type(),
            should: filter_type(),
            must_not: filter_type()
          }
          | nil

  @type search_params :: %{
          hnsw_ef: integer() | nil,
          exact: boolean(),
          quantization: %{ignore: boolean() | false, rescore: boolean() | false} | nil
        }

  @type search_body :: %{
          vector: vector(),
          filter: %{must: filter_type(), should: filter_type(), must_not: filter_type()} | nil,
          params: search_params(),
          limit: integer(),
          offset: non_neg_integer(),
          with_payload: with_payload_interface(),
          with_vector: boolean() | list(String.t()),
          score_threshold: integer() | nil
        }

  @type set_payload_body :: %{payload: map(), points: extended_point_id(), filter: filter_type()}
  @type delete_payload_body :: %{keys: list(String.t()), points: extended_point_id(), filter: filter_type()}

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
  Retrieve full information of single point by id.

  ## Path parameters

  - collection_name **required** : Name of the collection to update from

  - id **required** : ID of the point to retrieve

  ## Query parameters

  - `consistency` *optional* : Define read consistency guarantees for the operation
  """
  @spec get_point(String.t(), String.t() | non_neg_integer(), consistency() | nil) :: {:ok, map()} | {:error, any()}
  def get_point(collection_name, id, consistency \\ nil) do
    path =
      "/collections/#{collection_name}/points/#{id}"
      |> Client.add_query_param("consistency", consistency)

    client()
    |> Tesla.get(path)
    |> parse_response()
  end

  @doc """
  Retrieve multiple points by specified IDs.

  ## Path parameters

  - collection_name **required** : Name of the collection to update from

  ## Query parameters

  - `consistency` *optional* : Define read consistency guarantees for the operation

  ## Request body schema

  - `ids` **required** : List of IDs to retrieve
  - `with_payload` *optional* : Select which payload to return with the response. Default: All
  - `with_vector` *optional* : Options for specifying which vector to include
  """

  @spec get_points(String.t(), get_points_body(), consistency() | nil) :: {:ok, map()} | {:error, any()}
  def get_points(collection_name, body, consistency \\ nil) do
    path =
      "/collections/#{collection_name}/points"
      |> Client.add_query_param("consistency", consistency)

    client()
    |> Tesla.post(path, body)
    |> parse_response()
  end

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
      "/collections/#{collection_name}/points"
      |> Client.add_query_param("wait", wait)
      |> Client.add_query_param("ordering", ordering)

    client()
    |> Tesla.put(path, body)
    |> parse_response()
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
      "/collections/#{collection_name}/points/delete"
      |> Client.add_query_param("wait", wait)
      |> Client.add_query_param("ordering", ordering)

    client()
    |> Tesla.post(path, body)
    |> parse_response()
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
      "/collections/#{collection_name}/points/payload"
      |> Client.add_query_param("wait", wait)
      |> Client.add_query_param("ordering", ordering)

    client()
    |> Tesla.post(path, body)
    |> parse_response()
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
      "/collections/#{collection_name}/points/payload"
      |> Client.add_query_param("wait", wait)
      |> Client.add_query_param("ordering", ordering)

    client()
    |> Tesla.put(path, body)
    |> parse_response()
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
      "/collections/#{collection_name}/points/payload/delete"
      |> Client.add_query_param("wait", wait)
      |> Client.add_query_param("ordering", ordering)

    client()
    |> Tesla.post(path, body)
    |> parse_response()
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
      "/collections/#{collection_name}/points/payload/clear"
      |> Client.add_query_param("wait", wait)
      |> Client.add_query_param("ordering", ordering)

    client()
    |> Tesla.post(path, body)
    |> parse_response()
  end

  @doc """
  Batch update points in a collection.

  ## Path parameters

  - collection_name **required** : Name of the collection to apply operations on

  ## Query parameters

  - `wait` *optional* : If true, wait for changes to actually happen
  - `ordering` *optional* : Define ordering guarantees for the operation

  ## Request body

  - Described by the `UpdateOperations` schema, includes update operations.

  ## Response

  - On success, returns an array of `UpdateResult`.

  """
  @spec batch_update_points(String.t(), map(), boolean() | nil, String.t() | nil) :: {:ok, map()} | {:error, any()}
  def batch_update_points(collection_name, update_operations, wait \\ false, ordering \\ nil) do
    path =
      "/collections/#{collection_name}/points/batch"
      |> Client.add_query_param("wait", wait)
      |> Client.add_query_param("ordering", ordering)

    client()
    |> Tesla.post(path, update_operations)
    |> parse_response()
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
      "/collections/#{collection_name}/points/scroll"
      |> Client.add_query_param("consistency", consistency)

    client()
    |> Tesla.post(path, body)
    |> parse_response()
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
      "/collections/#{collection_name}/points/search"
      |> Client.add_query_param("consistency", consistency)

    client()
    |> Tesla.post(path, body)
    |> parse_response()
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
      "/collections/#{collection_name}/points/search/batch"
      |> Client.add_query_param("consistency", consistency)

    client()
    |> Tesla.post(path, body)
    |> parse_response()
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
      "/collections/#{collection_name}/points/recommend"
      |> Client.add_query_param("consistency", consistency)

    client()
    |> Tesla.post(path, body)
    |> parse_response()
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
      "/collections/#{collection_name}/points/recommend/batch"
      |> Client.add_query_param("consistency", consistency)

    client()
    |> Tesla.post(path, body)
    |> parse_response()
  end

  @doc """
  Update specified vectors on points.

  ## Path parameters

  - collection_name **required** : Name of the collection to update vectors in

  ## Query parameters

  - `wait` *optional* : If true, wait for changes to actually happen
  - `ordering` *optional* : Define ordering guarantees for the operation

  ## Request body schema

  - `points` **required** : List of points to update vectors for
  - `vector` **required** : Vector to update
  """
  @spec update_vectors(String.t(), map(), boolean() | nil, ordering() | nil) :: {:ok, map()} | {:error, any()}
  def update_vectors(collection_name, body, wait \\ false, ordering \\ nil) do
    path =
      "/collections/#{collection_name}/points/vectors"
      |> Client.add_query_param("wait", wait)
      |> Client.add_query_param("ordering", ordering)

    client()
    |> Tesla.put(path, body)
    |> parse_response()
  end

  @doc """
  Delete specified vectors from points.

  ## Path parameters

  - collection_name **required** : Name of the collection to delete vectors from

  ## Query parameters

  - `wait` *optional* : If true, wait for changes to actually happen
  - `ordering` *optional* : Define ordering guarantees for the operation

  ## Request body schema

  - `points` **required** : List of points to delete vectors from
  - `vector` **required** : Vector name to delete
  """
  @spec delete_vectors(String.t(), map(), boolean() | nil, ordering() | nil) :: {:ok, map()} | {:error, any()}
  def delete_vectors(collection_name, body, wait \\ false, ordering \\ nil) do
    path =
      "/collections/#{collection_name}/points/vectors/delete"
      |> Client.add_query_param("wait", wait)
      |> Client.add_query_param("ordering", ordering)

    client()
    |> Tesla.post(path, body)
    |> parse_response()
  end

  @doc """
  Search points grouped by a given field.

  ## Path parameters

  - collection_name **required** : Name of the collection to search in

  ## Query parameters

  - `consistency` *optional* : Define read consistency guarantees for the operation

  ## Request body schema

  Similar to search_points but with grouping parameters
  """
  @spec search_points_groups(String.t(), map(), consistency() | nil) :: {:ok, map()} | {:error, any()}
  def search_points_groups(collection_name, body, consistency \\ nil) do
    path =
      "/collections/#{collection_name}/points/search/groups"
      |> Client.add_query_param("consistency", consistency)

    client()
    |> Tesla.post(path, body)
    |> parse_response()
  end

  @doc """
  Recommend points grouped by a given field.

  ## Path parameters

  - collection_name **required** : Name of the collection to search in

  ## Query parameters

  - `consistency` *optional* : Define read consistency guarantees for the operation

  ## Request body schema

  Similar to recommend_points but with grouping parameters
  """
  @spec recommend_points_groups(String.t(), map(), consistency() | nil) :: {:ok, map()} | {:error, any()}
  def recommend_points_groups(collection_name, body, consistency \\ nil) do
    path =
      "/collections/#{collection_name}/points/recommend/groups"
      |> Client.add_query_param("consistency", consistency)

    client()
    |> Tesla.post(path, body)
    |> parse_response()
  end

  @doc """
  Discover points using context pairs.

  ## Path parameters

  - collection_name **required** : Name of the collection to search in

  ## Query parameters

  - `consistency` *optional* : Define read consistency guarantees for the operation

  ## Request body schema

  - `context` **required** : Pairs of {positive, negative} examples
  - `target` *optional* : Target vector to discover
  - Other similar parameters to search
  """
  @spec discover_points(String.t(), map(), consistency() | nil) :: {:ok, map()} | {:error, any()}
  def discover_points(collection_name, body, consistency \\ nil) do
    path =
      "/collections/#{collection_name}/points/discover"
      |> Client.add_query_param("consistency", consistency)

    client()
    |> Tesla.post(path, body)
    |> parse_response()
  end

  @doc """
  Discover points using context pairs in batch.

  ## Path parameters

  - collection_name **required** : Name of the collection to search in

  ## Query parameters

  - `consistency` *optional* : Define read consistency guarantees for the operation

  ## Request body schema

  - `searches` **required** : List of discover requests
  """
  @spec discover_points_batch(String.t(), list(map()), consistency() | nil) :: {:ok, map()} | {:error, any()}
  def discover_points_batch(collection_name, body, consistency \\ nil) do
    path =
      "/collections/#{collection_name}/points/discover/batch"
      |> Client.add_query_param("consistency", consistency)

    client()
    |> Tesla.post(path, body)
    |> parse_response()
  end

  @doc """
  Calculate facet aggregation for points.

  ## Path parameters

  - collection_name **required** : Name of the collection

  ## Request body schema

  - `facet` **required** : Facet configuration
  - `filter` *optional* : Filter to apply
  """
  @spec facet_points(String.t(), map()) :: {:ok, map()} | {:error, any()}
  def facet_points(collection_name, body) do
    path = "/collections/#{collection_name}/facet"

    client()
    |> Tesla.post(path, body)
    |> parse_response()
  end

  @doc """
  Query points using a query string.

  ## Path parameters

  - collection_name **required** : Name of the collection to query

  ## Query parameters

  - `consistency` *optional* : Define read consistency guarantees for the operation

  ## Request body schema

  - `query` **required** : Query string or vector query
  - Other similar parameters to search
  """
  @spec query_points(String.t(), map(), consistency() | nil) :: {:ok, map()} | {:error, any()}
  def query_points(collection_name, body, consistency \\ nil) do
    path =
      "/collections/#{collection_name}/points/query"
      |> Client.add_query_param("consistency", consistency)

    client()
    |> Tesla.post(path, body)
    |> parse_response()
  end

  @doc """
  Query points using a query string in batch.

  ## Path parameters

  - collection_name **required** : Name of the collection to query

  ## Query parameters

  - `consistency` *optional* : Define read consistency guarantees for the operation

  ## Request body schema

  - `searches` **required** : List of query requests
  """
  @spec query_points_batch(String.t(), list(map()), consistency() | nil) :: {:ok, map()} | {:error, any()}
  def query_points_batch(collection_name, body, consistency \\ nil) do
    path =
      "/collections/#{collection_name}/points/query/batch"
      |> Client.add_query_param("consistency", consistency)

    client()
    |> Tesla.post(path, body)
    |> parse_response()
  end

  @doc """
  Query points grouped by a given field.

  ## Path parameters

  - collection_name **required** : Name of the collection to query

  ## Query parameters

  - `consistency` *optional* : Define read consistency guarantees for the operation

  ## Request body schema

  Similar to query_points but with grouping parameters
  """
  @spec query_points_groups(String.t(), map(), consistency() | nil) :: {:ok, map()} | {:error, any()}
  def query_points_groups(collection_name, body, consistency \\ nil) do
    path =
      "/collections/#{collection_name}/points/query/groups"
      |> Client.add_query_param("consistency", consistency)

    client()
    |> Tesla.post(path, body)
    |> parse_response()
  end

  @doc """
  Search points by vector pairs.

  ## Path parameters

  - collection_name **required** : Name of the collection to search in

  ## Request body schema

  - `searches` **required** : List of vector pairs to search
  """
  @spec search_matrix_pairs(String.t(), map()) :: {:ok, map()} | {:error, any()}
  def search_matrix_pairs(collection_name, body) do
    path = "/collections/#{collection_name}/points/search/matrix/pairs"

    client()
    |> Tesla.post(path, body)
    |> parse_response()
  end

  @doc """
  Search points by vector offsets.

  ## Path parameters

  - collection_name **required** : Name of the collection to search in

  ## Request body schema

  - `searches` **required** : List of vector offsets to search
  """
  @spec search_matrix_offsets(String.t(), map()) :: {:ok, map()} | {:error, any()}
  def search_matrix_offsets(collection_name, body) do
    path = "/collections/#{collection_name}/points/search/matrix/offsets"

    client()
    |> Tesla.post(path, body)
    |> parse_response()
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
    path = "/collections/#{collection_name}/points/count"

    client()
    |> Tesla.post(path, body)
    |> parse_response()
  end

  # Private helpers
  defp parse_response({:ok, %Tesla.Env{status: 200, body: body}}) do
    {:ok, body}
  end

  defp parse_response({:error, reason}) do
    {:error, reason}
  end

  defp parse_response({:ok, %Tesla.Env{} = env}) do
    {:error, %{status: env.status, body: env.body}}
  end
end
