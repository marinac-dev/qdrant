defmodule Qdrant.Api.Http.Points do
  @moduledoc """
  Client-aware Qdrant points and search API.

  Each operation accepts a `Qdrant.Client` first and a keyword list of request
  options last. No-client positional forms remain available for compatibility.
  """

  alias Qdrant.Api.Http.Request
  alias Qdrant.{Client, Config, Types}

  @consistency [:consistency]
  @get_points_options [:consistency, :timeout]
  @write_options [:wait, :ordering, :timeout]
  @search_options [:consistency, :timeout]
  @timeout [:timeout]

  @compat_operations [
    get_point: 3,
    get_points: 3,
    upsert_points: 3,
    delete_points: 3,
    set_payload: 3,
    overwrite_payload: 3,
    delete_payload: 3,
    clear_payload: 3,
    batch_update_points: 3,
    scroll_points: 3,
    search_points: 3,
    search_points_batch: 3,
    recommend_points: 3,
    recommend_points_batch: 3,
    update_vectors: 3,
    delete_vectors: 3,
    search_points_groups: 3,
    recommend_points_groups: 3,
    discover_points: 3,
    discover_points_batch: 3,
    facet_points: 3,
    query_points: 3,
    query_points_batch: 3,
    query_points_groups: 3,
    search_matrix_pairs: 3,
    search_matrix_offsets: 3,
    count_points: 3
  ]

  @doc """
  Retrieves one point. Options: `:consistency`.
  """
  @spec get_point(Client.t(), String.t(), Types.extended_point_id(), Types.request_options()) :: Types.result()
  def get_point(%Client{} = client, collection_name, id, opts) do
    request(client, :get, points_path(collection_name) <> "/" <> Request.segment(id), :no_body, opts, @consistency)
  end

  def get_point(%Client{} = client, collection_name, id), do: get_point(client, collection_name, id, [])

  def get_point(collection_name, id, consistency),
    do: compat(:get_point, [collection_name, id, [consistency: consistency]])

  def get_point(collection_name, id), do: compat(:get_point, [collection_name, id, []])

  @doc """
  Retrieves points by ID. Options: `:consistency`, `:timeout`.
  """
  @spec get_points(Client.t(), String.t(), Types.request_body(), Types.request_options()) :: Types.result()
  def get_points(%Client{} = client, collection_name, body, opts) do
    request(client, :post, points_path(collection_name), body, opts, @get_points_options)
  end

  def get_points(collection_name, body, consistency, timeout),
    do: compat(:get_points, [collection_name, body, [consistency: consistency, timeout: timeout]])

  def get_points(%Client{} = client, collection_name, body), do: get_points(client, collection_name, body, [])

  def get_points(collection_name, body, consistency),
    do: compat(:get_points, [collection_name, body, [consistency: consistency]])

  def get_points(collection_name, body), do: compat(:get_points, [collection_name, body, []])

  @doc """
  Inserts or replaces points. Options: `:wait`, `:ordering`, `:timeout`.
  """
  @spec upsert_points(Client.t(), String.t(), Types.request_body(), Types.request_options()) :: Types.result()
  def upsert_points(%Client{} = client, collection_name, body, opts) do
    request(client, :put, points_path(collection_name), body, opts, @write_options)
  end

  def upsert_points(collection_name, body, wait, ordering),
    do: compat(:upsert_points, [collection_name, body, [wait: wait, ordering: ordering]])

  def upsert_points(collection_name, body, wait, ordering, timeout),
    do: compat(:upsert_points, [collection_name, body, [wait: wait, ordering: ordering, timeout: timeout]])

  def upsert_points(%Client{} = client, collection_name, body), do: upsert_points(client, collection_name, body, [])
  def upsert_points(collection_name, body, wait), do: compat(:upsert_points, [collection_name, body, [wait: wait]])
  def upsert_points(collection_name, body), do: compat(:upsert_points, [collection_name, body, [wait: false]])

  @doc """
  Deletes points selected by the request body. Options: `:wait`, `:ordering`, `:timeout`.
  """
  @spec delete_points(Client.t(), String.t(), Types.request_body(), Types.request_options()) :: Types.result()
  def delete_points(%Client{} = client, collection_name, body, opts) do
    request(client, :post, points_path(collection_name) <> "/delete", body, opts, @write_options)
  end

  def delete_points(collection_name, body, wait, ordering),
    do: compat(:delete_points, [collection_name, body, [wait: wait, ordering: ordering]])

  def delete_points(collection_name, body, wait, ordering, timeout),
    do: compat(:delete_points, [collection_name, body, [wait: wait, ordering: ordering, timeout: timeout]])

  def delete_points(%Client{} = client, collection_name, body), do: delete_points(client, collection_name, body, [])
  def delete_points(collection_name, body, wait), do: compat(:delete_points, [collection_name, body, [wait: wait]])
  def delete_points(collection_name, body), do: compat(:delete_points, [collection_name, body, [wait: false]])

  @doc """
  Sets payload values. Options: `:wait`, `:ordering`, `:timeout`.
  """
  @spec set_payload(Client.t(), String.t(), Types.request_body(), Types.request_options()) :: Types.result()
  def set_payload(%Client{} = client, collection_name, body, opts) do
    request(client, :post, points_path(collection_name) <> "/payload", body, opts, @write_options)
  end

  def set_payload(collection_name, body, wait, ordering),
    do: compat(:set_payload, [collection_name, body, [wait: wait, ordering: ordering]])

  def set_payload(collection_name, body, wait, ordering, timeout),
    do: compat(:set_payload, [collection_name, body, [wait: wait, ordering: ordering, timeout: timeout]])

  def set_payload(%Client{} = client, collection_name, body), do: set_payload(client, collection_name, body, [])
  def set_payload(collection_name, body, wait), do: compat(:set_payload, [collection_name, body, [wait: wait]])
  def set_payload(collection_name, body), do: compat(:set_payload, [collection_name, body, [wait: false]])

  @doc """
  Replaces complete payloads. Options: `:wait`, `:ordering`, `:timeout`.
  """
  @spec overwrite_payload(Client.t(), String.t(), Types.request_body(), Types.request_options()) :: Types.result()
  def overwrite_payload(%Client{} = client, collection_name, body, opts) do
    request(client, :put, points_path(collection_name) <> "/payload", body, opts, @write_options)
  end

  def overwrite_payload(collection_name, body, wait, ordering),
    do: compat(:overwrite_payload, [collection_name, body, [wait: wait, ordering: ordering]])

  def overwrite_payload(collection_name, body, wait, ordering, timeout),
    do: compat(:overwrite_payload, [collection_name, body, [wait: wait, ordering: ordering, timeout: timeout]])

  def overwrite_payload(%Client{} = client, collection_name, body),
    do: overwrite_payload(client, collection_name, body, [])

  def overwrite_payload(collection_name, body, wait),
    do: compat(:overwrite_payload, [collection_name, body, [wait: wait]])

  def overwrite_payload(collection_name, body), do: compat(:overwrite_payload, [collection_name, body, [wait: false]])

  @doc """
  Deletes payload keys. Options: `:wait`, `:ordering`, `:timeout`.
  """
  @spec delete_payload(Client.t(), String.t(), Types.request_body(), Types.request_options()) :: Types.result()
  def delete_payload(%Client{} = client, collection_name, body, opts) do
    request(client, :post, points_path(collection_name) <> "/payload/delete", body, opts, @write_options)
  end

  def delete_payload(collection_name, body, wait, ordering),
    do: compat(:delete_payload, [collection_name, body, [wait: wait, ordering: ordering]])

  def delete_payload(collection_name, body, wait, ordering, timeout),
    do: compat(:delete_payload, [collection_name, body, [wait: wait, ordering: ordering, timeout: timeout]])

  def delete_payload(%Client{} = client, collection_name, body), do: delete_payload(client, collection_name, body, [])
  def delete_payload(collection_name, body, wait), do: compat(:delete_payload, [collection_name, body, [wait: wait]])
  def delete_payload(collection_name, body), do: compat(:delete_payload, [collection_name, body, [wait: false]])

  @doc """
  Clears payloads selected by a map such as `%{points: [1, 2]}` or
  `%{filter: %{must: [...]}}`. Options: `:wait`, `:ordering`, `:timeout`.
  """
  @spec clear_payload(Client.t(), String.t(), Types.request_body(), Types.request_options()) :: Types.result()
  def clear_payload(%Client{} = client, collection_name, body, opts) do
    request(client, :post, points_path(collection_name) <> "/payload/clear", body, opts, @write_options)
  end

  def clear_payload(collection_name, body, wait, ordering),
    do: compat(:clear_payload, [collection_name, body, [wait: wait, ordering: ordering]])

  def clear_payload(collection_name, body, wait, ordering, timeout),
    do: compat(:clear_payload, [collection_name, body, [wait: wait, ordering: ordering, timeout: timeout]])

  def clear_payload(%Client{} = client, collection_name, body), do: clear_payload(client, collection_name, body, [])
  def clear_payload(collection_name, body, wait), do: compat(:clear_payload, [collection_name, body, [wait: wait]])
  def clear_payload(collection_name, body), do: compat(:clear_payload, [collection_name, body, [wait: false]])

  @doc """
  Applies a batch of point updates. Options: `:wait`, `:ordering`, `:timeout`.
  """
  @spec batch_update_points(Client.t(), String.t(), Types.request_body(), Types.request_options()) :: Types.result()
  def batch_update_points(%Client{} = client, collection_name, body, opts) do
    request(client, :post, points_path(collection_name) <> "/batch", body, opts, @write_options)
  end

  def batch_update_points(collection_name, body, wait, ordering),
    do: compat(:batch_update_points, [collection_name, body, [wait: wait, ordering: ordering]])

  def batch_update_points(collection_name, body, wait, ordering, timeout),
    do: compat(:batch_update_points, [collection_name, body, [wait: wait, ordering: ordering, timeout: timeout]])

  def batch_update_points(%Client{} = client, collection_name, body),
    do: batch_update_points(client, collection_name, body, [])

  def batch_update_points(collection_name, body, wait),
    do: compat(:batch_update_points, [collection_name, body, [wait: wait]])

  def batch_update_points(collection_name, body),
    do: compat(:batch_update_points, [collection_name, body, [wait: false]])

  @doc """
  Scrolls through points. Options: `:consistency`, `:timeout`.
  """
  @spec scroll_points(Client.t(), String.t(), Types.request_body(), Types.request_options()) :: Types.result()
  def scroll_points(%Client{} = client, collection_name, body, opts) do
    request(client, :post, points_path(collection_name) <> "/scroll", body, opts, @search_options)
  end

  def scroll_points(%Client{} = client, collection_name, body), do: scroll_points(client, collection_name, body, [])

  def scroll_points(collection_name, body, consistency),
    do: compat(:scroll_points, [collection_name, body, [consistency: consistency]])

  def scroll_points(collection_name, body), do: compat(:scroll_points, [collection_name, body, []])

  @doc """
  Searches for nearest points. Options: `:consistency`, `:timeout`.
  """
  @spec search_points(Client.t(), String.t(), Types.request_body(), Types.request_options()) :: Types.result()
  def search_points(%Client{} = client, collection_name, body, opts) do
    request(client, :post, points_path(collection_name) <> "/search", body, opts, @search_options)
  end

  def search_points(%Client{} = client, collection_name, body), do: search_points(client, collection_name, body, [])

  def search_points(collection_name, body, consistency),
    do: compat(:search_points, [collection_name, body, [consistency: consistency]])

  def search_points(collection_name, body), do: compat(:search_points, [collection_name, body, []])

  @doc """
  Runs batch search. The body must be `%{searches: [search, ...]}`.
  Options: `:consistency`, `:timeout`.
  """
  @spec search_points_batch(Client.t(), String.t(), Types.batch_request(), Types.request_options()) :: Types.result()
  def search_points_batch(%Client{} = client, collection_name, body, opts) do
    request(client, :post, points_path(collection_name) <> "/search/batch", body, opts, @search_options)
  end

  def search_points_batch(%Client{} = client, collection_name, body),
    do: search_points_batch(client, collection_name, body, [])

  def search_points_batch(collection_name, body, consistency),
    do: compat(:search_points_batch, [collection_name, body, [consistency: consistency]])

  def search_points_batch(collection_name, body), do: compat(:search_points_batch, [collection_name, body, []])

  @doc """
  Recommends points. Options: `:consistency`, `:timeout`.
  """
  @spec recommend_points(Client.t(), String.t(), Types.request_body(), Types.request_options()) :: Types.result()
  def recommend_points(%Client{} = client, collection_name, body, opts) do
    request(client, :post, points_path(collection_name) <> "/recommend", body, opts, @search_options)
  end

  def recommend_points(%Client{} = client, collection_name, body),
    do: recommend_points(client, collection_name, body, [])

  def recommend_points(collection_name, body, consistency),
    do: compat(:recommend_points, [collection_name, body, [consistency: consistency]])

  def recommend_points(collection_name, body), do: compat(:recommend_points, [collection_name, body, []])

  @doc """
  Runs batch recommendation. The body must be `%{searches: [recommendation, ...]}`.
  Options: `:consistency`, `:timeout`.
  """
  @spec recommend_points_batch(Client.t(), String.t(), Types.batch_request(), Types.request_options()) :: Types.result()
  def recommend_points_batch(%Client{} = client, collection_name, body, opts) do
    request(client, :post, points_path(collection_name) <> "/recommend/batch", body, opts, @search_options)
  end

  def recommend_points_batch(%Client{} = client, collection_name, body),
    do: recommend_points_batch(client, collection_name, body, [])

  def recommend_points_batch(collection_name, body, consistency),
    do: compat(:recommend_points_batch, [collection_name, body, [consistency: consistency]])

  def recommend_points_batch(collection_name, body), do: compat(:recommend_points_batch, [collection_name, body, []])

  @doc """
  Updates vectors. Options: `:wait`, `:ordering`, `:timeout`.
  """
  @spec update_vectors(Client.t(), String.t(), Types.request_body(), Types.request_options()) :: Types.result()
  def update_vectors(%Client{} = client, collection_name, body, opts) do
    request(client, :put, points_path(collection_name) <> "/vectors", body, opts, @write_options)
  end

  def update_vectors(collection_name, body, wait, ordering),
    do: compat(:update_vectors, [collection_name, body, [wait: wait, ordering: ordering]])

  def update_vectors(collection_name, body, wait, ordering, timeout),
    do: compat(:update_vectors, [collection_name, body, [wait: wait, ordering: ordering, timeout: timeout]])

  def update_vectors(%Client{} = client, collection_name, body), do: update_vectors(client, collection_name, body, [])
  def update_vectors(collection_name, body, wait), do: compat(:update_vectors, [collection_name, body, [wait: wait]])
  def update_vectors(collection_name, body), do: compat(:update_vectors, [collection_name, body, [wait: false]])

  @doc """
  Deletes vectors. Options: `:wait`, `:ordering`, `:timeout`.
  """
  @spec delete_vectors(Client.t(), String.t(), Types.request_body(), Types.request_options()) :: Types.result()
  def delete_vectors(%Client{} = client, collection_name, body, opts) do
    request(client, :post, points_path(collection_name) <> "/vectors/delete", body, opts, @write_options)
  end

  def delete_vectors(collection_name, body, wait, ordering),
    do: compat(:delete_vectors, [collection_name, body, [wait: wait, ordering: ordering]])

  def delete_vectors(collection_name, body, wait, ordering, timeout),
    do: compat(:delete_vectors, [collection_name, body, [wait: wait, ordering: ordering, timeout: timeout]])

  def delete_vectors(%Client{} = client, collection_name, body), do: delete_vectors(client, collection_name, body, [])
  def delete_vectors(collection_name, body, wait), do: compat(:delete_vectors, [collection_name, body, [wait: wait]])
  def delete_vectors(collection_name, body), do: compat(:delete_vectors, [collection_name, body, [wait: false]])

  @doc """
  Searches points grouped by a field. Options: `:consistency`, `:timeout`.
  """
  @spec search_points_groups(Client.t(), String.t(), Types.request_body(), Types.request_options()) :: Types.result()
  def search_points_groups(%Client{} = client, collection_name, body, opts) do
    request(client, :post, points_path(collection_name) <> "/search/groups", body, opts, @search_options)
  end

  def search_points_groups(%Client{} = client, collection_name, body),
    do: search_points_groups(client, collection_name, body, [])

  def search_points_groups(collection_name, body, consistency),
    do: compat(:search_points_groups, [collection_name, body, [consistency: consistency]])

  def search_points_groups(collection_name, body), do: compat(:search_points_groups, [collection_name, body, []])

  @doc """
  Recommends points grouped by a field. Options: `:consistency`, `:timeout`.
  """
  @spec recommend_points_groups(Client.t(), String.t(), Types.request_body(), Types.request_options()) :: Types.result()
  def recommend_points_groups(%Client{} = client, collection_name, body, opts) do
    request(client, :post, points_path(collection_name) <> "/recommend/groups", body, opts, @search_options)
  end

  def recommend_points_groups(%Client{} = client, collection_name, body),
    do: recommend_points_groups(client, collection_name, body, [])

  def recommend_points_groups(collection_name, body, consistency),
    do: compat(:recommend_points_groups, [collection_name, body, [consistency: consistency]])

  def recommend_points_groups(collection_name, body), do: compat(:recommend_points_groups, [collection_name, body, []])

  @doc """
  Discovers points from context pairs. Options: `:consistency`, `:timeout`.
  """
  @spec discover_points(Client.t(), String.t(), Types.request_body(), Types.request_options()) :: Types.result()
  def discover_points(%Client{} = client, collection_name, body, opts) do
    request(client, :post, points_path(collection_name) <> "/discover", body, opts, @search_options)
  end

  def discover_points(%Client{} = client, collection_name, body), do: discover_points(client, collection_name, body, [])

  def discover_points(collection_name, body, consistency),
    do: compat(:discover_points, [collection_name, body, [consistency: consistency]])

  def discover_points(collection_name, body), do: compat(:discover_points, [collection_name, body, []])

  @doc """
  Runs batch discovery. The body must be `%{searches: [discovery, ...]}`.
  Options: `:consistency`, `:timeout`.
  """
  @spec discover_points_batch(Client.t(), String.t(), Types.batch_request(), Types.request_options()) :: Types.result()
  def discover_points_batch(%Client{} = client, collection_name, body, opts) do
    request(client, :post, points_path(collection_name) <> "/discover/batch", body, opts, @search_options)
  end

  def discover_points_batch(%Client{} = client, collection_name, body),
    do: discover_points_batch(client, collection_name, body, [])

  def discover_points_batch(collection_name, body, consistency),
    do: compat(:discover_points_batch, [collection_name, body, [consistency: consistency]])

  def discover_points_batch(collection_name, body), do: compat(:discover_points_batch, [collection_name, body, []])

  @doc """
  Calculates facet values. Options: `:consistency`, `:timeout`.
  """
  @spec facet_points(Client.t(), String.t(), Types.request_body(), Types.request_options()) :: Types.result()
  def facet_points(%Client{} = client, collection_name, body, opts) do
    request(client, :post, collection_path(collection_name) <> "/facet", body, opts, @search_options)
  end

  def facet_points(%Client{} = client, collection_name, body), do: facet_points(client, collection_name, body, [])
  def facet_points(collection_name, body), do: compat(:facet_points, [collection_name, body, []])

  @doc """
  Runs a universal query. `:query` may be omitted for ID-ordered retrieval.
  Options: `:consistency`, `:timeout`.
  """
  @spec query_points(Client.t(), String.t(), Types.request_body(), Types.request_options()) :: Types.result()
  def query_points(%Client{} = client, collection_name, body, opts) do
    request(client, :post, points_path(collection_name) <> "/query", body, opts, @search_options)
  end

  def query_points(%Client{} = client, collection_name, body), do: query_points(client, collection_name, body, [])

  def query_points(collection_name, body, consistency),
    do: compat(:query_points, [collection_name, body, [consistency: consistency]])

  def query_points(collection_name, body), do: compat(:query_points, [collection_name, body, []])

  @doc """
  Runs batch universal queries. The body must be `%{searches: [query, ...]}`.
  Options: `:consistency`, `:timeout`.
  """
  @spec query_points_batch(Client.t(), String.t(), Types.batch_request(), Types.request_options()) :: Types.result()
  def query_points_batch(%Client{} = client, collection_name, body, opts) do
    request(client, :post, points_path(collection_name) <> "/query/batch", body, opts, @search_options)
  end

  def query_points_batch(%Client{} = client, collection_name, body),
    do: query_points_batch(client, collection_name, body, [])

  def query_points_batch(collection_name, body, consistency),
    do: compat(:query_points_batch, [collection_name, body, [consistency: consistency]])

  def query_points_batch(collection_name, body), do: compat(:query_points_batch, [collection_name, body, []])

  @doc """
  Runs a grouped universal query. Options: `:consistency`, `:timeout`.
  """
  @spec query_points_groups(Client.t(), String.t(), Types.request_body(), Types.request_options()) :: Types.result()
  def query_points_groups(%Client{} = client, collection_name, body, opts) do
    request(client, :post, points_path(collection_name) <> "/query/groups", body, opts, @search_options)
  end

  def query_points_groups(%Client{} = client, collection_name, body),
    do: query_points_groups(client, collection_name, body, [])

  def query_points_groups(collection_name, body, consistency),
    do: compat(:query_points_groups, [collection_name, body, [consistency: consistency]])

  def query_points_groups(collection_name, body), do: compat(:query_points_groups, [collection_name, body, []])

  @doc """
  Calculates a distance matrix as point pairs. Options: `:consistency`, `:timeout`.
  """
  @spec search_matrix_pairs(Client.t(), String.t(), Types.request_body(), Types.request_options()) :: Types.result()
  def search_matrix_pairs(%Client{} = client, collection_name, body, opts) do
    request(client, :post, points_path(collection_name) <> "/search/matrix/pairs", body, opts, @search_options)
  end

  def search_matrix_pairs(%Client{} = client, collection_name, body),
    do: search_matrix_pairs(client, collection_name, body, [])

  def search_matrix_pairs(collection_name, body), do: compat(:search_matrix_pairs, [collection_name, body, []])

  @doc """
  Calculates a distance matrix as offsets. Options: `:consistency`, `:timeout`.
  """
  @spec search_matrix_offsets(Client.t(), String.t(), Types.request_body(), Types.request_options()) :: Types.result()
  def search_matrix_offsets(%Client{} = client, collection_name, body, opts) do
    request(client, :post, points_path(collection_name) <> "/search/matrix/offsets", body, opts, @search_options)
  end

  def search_matrix_offsets(%Client{} = client, collection_name, body),
    do: search_matrix_offsets(client, collection_name, body, [])

  def search_matrix_offsets(collection_name, body), do: compat(:search_matrix_offsets, [collection_name, body, []])

  @doc """
  Counts points matching the request body. Options: `:timeout`.
  """
  @spec count_points(Client.t(), String.t(), Types.request_body(), Types.request_options()) :: Types.result()
  def count_points(%Client{} = client, collection_name, body, opts) do
    request(client, :post, points_path(collection_name) <> "/count", body, opts, @timeout)
  end

  def count_points(%Client{} = client, collection_name, body), do: count_points(client, collection_name, body, [])
  def count_points(collection_name, body), do: compat(:count_points, [collection_name, body, []])

  defp request(client, method, path, :no_body, opts, query_options) do
    Request.request(client, method, path, query: Keyword.take(opts, query_options))
  end

  defp request(client, method, path, body, opts, query_options) do
    Request.request(client, method, path, body: body, query: Keyword.take(opts, query_options))
  end

  defp collection_path(collection_name), do: "/collections/" <> Request.segment(collection_name)
  defp points_path(collection_name), do: collection_path(collection_name) <> "/points"

  for {function, arity} <- @compat_operations do
    args = Macro.generate_arguments(arity, __MODULE__)

    defp compat(unquote(function), [unquote_splicing(args)]) do
      with {:ok, options} <- Config.client_options(),
           {:ok, client} <- Client.new(options) do
        unquote(function)(client, unquote_splicing(args))
      end
    end
  end
end
