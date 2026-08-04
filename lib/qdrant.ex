defmodule Qdrant do
  @moduledoc """
  Qdrant Elixir client for interacting with Qdrant vector database.

  Client-first functions use an explicit `Qdrant.Client`. Compatibility forms
  without a client build one with `default_client/0`.

  Successful calls return the complete Qdrant response envelope. The facade
  never unwraps the `"result"`, `"status"`, or `"time"` fields. Text and binary
  endpoint responses are likewise returned unchanged.

  ## Examples

      client = Qdrant.Client.new!(url: "http://localhost:6333")

      {:ok, _response} = Qdrant.list_collections(client)

      {:ok, _response} =
        Qdrant.create_collection(client, "articles", %{
          vectors: %{size: 42, distance: "Cosine"}
        })

  Client-first functions accept request options as their final argument when
  the endpoint supports them. Compatibility functions remain available, but
  explicit clients are preferred for applications that connect to more than
  one Qdrant instance.
  """

  alias Qdrant.Api.Http.{Aliases, Cluster, Collections, Indexes, Points, Service, Snapshots}
  alias Qdrant.{Client, Config, Error, Types}

  @doc "Builds a client from application and environment compatibility configuration."
  @spec default_client() :: {:ok, Client.t()} | {:error, Error.t()}
  def default_client do
    with {:ok, opts} <- Config.client_options(),
         {:ok, client} <- Client.new(opts) do
      {:ok, client}
    end
  end

  @doc "Builds the default client, raising `Qdrant.Error` for invalid configuration."
  @spec default_client!() :: Client.t()
  def default_client! do
    case default_client() do
      {:ok, client} -> client
      {:error, error} -> raise error
    end
  end

  # Each entry is {endpoint module, operation, required argument count,
  # endpoint accepts opts?, no-client compatibility shape}.
  @operations [
    {Collections, :list_collections, 0, true, {:positional, []}},
    {Collections, :get_collection, 1, true, {:positional, []}},
    {Collections, :create_collection, 2, true, {:positional, [timeout: nil]}},
    {Collections, :update_collection, 2, true, {:positional, [timeout: nil]}},
    {Collections, :delete_collection, 1, true, {:positional, [timeout: nil]}},
    {Collections, :collection_exists, 1, true, {:positional, []}},
    {Collections, :create_vector_name, 3, true, {:positional, [wait: nil, ordering: nil, timeout: nil]}},
    {Collections, :delete_vector_name, 2, true, {:positional, [wait: nil, ordering: nil, timeout: nil]}},
    {Collections, :get_optimizations, 1, true, :keyword},
    {Points, :get_point, 2, true, {:positional, [consistency: nil]}},
    {Points, :get_points, 2, true, {:positional, [consistency: nil, timeout: nil]}},
    {Points, :upsert_points, 2, true, {:positional, [wait: false, ordering: nil, timeout: nil]}},
    {Points, :delete_points, 2, true, {:positional, [wait: false, ordering: nil, timeout: nil]}},
    {Points, :set_payload, 2, true, {:positional, [wait: false, ordering: nil, timeout: nil]}},
    {Points, :overwrite_payload, 2, true, {:positional, [wait: false, ordering: nil, timeout: nil]}},
    {Points, :delete_payload, 2, true, {:positional, [wait: false, ordering: nil, timeout: nil]}},
    {Points, :clear_payload, 2, true, {:positional, [wait: false, ordering: nil, timeout: nil]}},
    {Points, :batch_update_points, 2, true, {:positional, [wait: false, ordering: nil, timeout: nil]}},
    {Points, :scroll_points, 2, true, {:positional, [consistency: nil]}},
    {Points, :search_points, 2, true, {:positional, [consistency: nil]}},
    {Points, :search_points_batch, 2, true, {:positional, [consistency: nil]}},
    {Points, :recommend_points, 2, true, {:positional, [consistency: nil]}},
    {Points, :recommend_points_batch, 2, true, {:positional, [consistency: nil]}},
    {Points, :update_vectors, 2, true, {:positional, [wait: false, ordering: nil, timeout: nil]}},
    {Points, :delete_vectors, 2, true, {:positional, [wait: false, ordering: nil, timeout: nil]}},
    {Points, :search_points_groups, 2, true, {:positional, [consistency: nil]}},
    {Points, :recommend_points_groups, 2, true, {:positional, [consistency: nil]}},
    {Points, :discover_points, 2, true, {:positional, [consistency: nil]}},
    {Points, :discover_points_batch, 2, true, {:positional, [consistency: nil]}},
    {Points, :facet_points, 2, true, {:positional, []}},
    {Points, :query_points, 2, true, {:positional, [consistency: nil]}},
    {Points, :query_points_batch, 2, true, {:positional, [consistency: nil]}},
    {Points, :query_points_groups, 2, true, {:positional, [consistency: nil]}},
    {Points, :search_matrix_pairs, 2, true, {:positional, []}},
    {Points, :search_matrix_offsets, 2, true, {:positional, []}},
    {Points, :count_points, 2, true, {:positional, []}},
    {Indexes, :create_field_index, 2, true, {:positional, [wait: nil, ordering: nil, timeout: nil]}},
    {Indexes, :delete_field_index, 2, true, {:positional, [wait: nil, ordering: nil, timeout: nil]}},
    {Aliases, :update_aliases, 1, true, {:positional, [timeout: nil]}},
    {Aliases, :get_collection_aliases, 1, true, {:positional, []}},
    {Aliases, :get_collections_aliases, 0, true, {:positional, []}},
    {Snapshots, :list_snapshots, 1, true, {:positional, []}},
    {Snapshots, :create_snapshot, 1, true, {:positional, [wait: nil]}},
    {Snapshots, :get_snapshot, 2, true, {:positional, []}},
    {Snapshots, :download_snapshot_to_file, 3, true, :keyword},
    {Snapshots, :delete_snapshot, 2, true, {:positional, [wait: nil]}},
    {Snapshots, :recover_from_snapshot, 2, true, {:positional, [wait: nil, priority: nil]}},
    {Snapshots, :recover_from_uploaded_snapshot, 2, true, {:positional, [wait: nil, priority: nil, checksum: nil]}},
    {Snapshots, :recover_from_uploaded_snapshot_file, 2, true, :keyword},
    {Snapshots, :list_full_snapshots, 0, true, {:positional, []}},
    {Snapshots, :create_full_snapshot, 0, true, {:positional, [wait: nil]}},
    {Snapshots, :get_full_snapshot, 1, true, {:positional, []}},
    {Snapshots, :download_full_snapshot_to_file, 2, true, :keyword},
    {Snapshots, :delete_full_snapshot, 1, true, {:positional, [wait: nil]}},
    {Snapshots, :list_shard_snapshots, 2, true, {:positional, []}},
    {Snapshots, :create_shard_snapshot, 2, true, {:positional, [wait: nil]}},
    {Snapshots, :get_shard_snapshot, 3, true, {:positional, []}},
    {Snapshots, :stream_shard_snapshot, 2, false, {:positional, []}},
    {Snapshots, :download_shard_snapshot_to_file, 4, true, :keyword},
    {Snapshots, :delete_shard_snapshot, 3, true, {:positional, [wait: nil]}},
    {Snapshots, :recover_shard_from_snapshot, 3, true, {:positional, [wait: nil, priority: nil]}},
    {Snapshots, :recover_shard_from_uploaded_snapshot, 3, true,
     {:positional, [wait: nil, priority: nil, checksum: nil]}},
    {Snapshots, :recover_shard_from_uploaded_snapshot_file, 3, true, :keyword},
    {Cluster, :create_shard_key, 2, true, {:positional, [timeout: nil]}},
    {Cluster, :delete_shard_key, 2, true, {:positional, [timeout: nil]}},
    {Cluster, :list_shard_keys, 1, false, {:positional, []}},
    {Cluster, :cluster_status, 0, false, {:positional, []}},
    {Cluster, :recover_current_peer, 0, false, {:positional, []}},
    {Cluster, :remove_peer, 1, true, {:positional, [force: nil]}},
    {Cluster, :collection_cluster_info, 1, false, {:positional, []}},
    {Cluster, :update_collection_cluster, 2, true, {:positional, [timeout: nil]}},
    {Cluster, :cluster_telemetry, 0, true, :keyword},
    {Service, :root, 0, false, {:positional, []}},
    {Service, :telemetry, 0, true,
     {:positional, [anonymize: nil, details_level: nil, per_collection: nil, timeout: nil]}},
    {Service, :metrics, 0, true, {:positional, [anonymize: nil, per_collection: nil, timeout: nil]}},
    {Service, :lock_options, 0, false, {:positional, []}},
    {Service, :set_lock_options, 1, false, {:positional, []}},
    {Service, :healthz, 0, false, {:positional, []}},
    {Service, :livez, 0, false, {:positional, []}},
    {Service, :readyz, 0, false, {:positional, []}},
    {Service, :get_issues, 0, false, {:positional, []}},
    {Service, :clear_issues, 0, false, {:positional, []}}
  ]

  for {endpoint, operation, required_count, supports_opts?, compatibility} <- @operations do
    optional_count =
      case compatibility do
        {:positional, defaults} -> length(defaults)
        :keyword -> 1
      end

    client_arities = if supports_opts?, do: [required_count + 1, required_count + 2], else: [required_count + 1]
    compatibility_arities = Enum.to_list(required_count..(required_count + optional_count))

    operation_doc = """
    Performs the `#{operation}` Qdrant REST operation.

    The client-first form accepts a `%Qdrant.Client{}` as its first argument.
    When supported, request options are passed as the final keyword list. The
    compatibility form omits the client and resolves one from application and
    environment configuration.

    Returns the complete Qdrant response envelope as `{:ok, response}` or a
    `{:error, %Qdrant.Error{}}` value. See `#{inspect(endpoint)}`
    for endpoint-specific request fields and options.
    """

    for arity <- Enum.uniq(client_arities ++ compatibility_arities) do
      argument_types = List.duplicate(quote(do: term()), arity)
      @spec unquote(operation)(unquote_splicing(argument_types)) :: Types.result()
    end

    required_args = Macro.generate_arguments(required_count, __MODULE__)

    if supports_opts? do
      @doc operation_doc
      def unquote(operation)(%Client{} = client, unquote_splicing(required_args), opts) when is_list(opts) do
        unquote(endpoint).unquote(operation)(client, unquote_splicing(required_args), opts)
      end

      @doc operation_doc
      def unquote(operation)(%Client{} = client, unquote_splicing(required_args)) do
        unquote(endpoint).unquote(operation)(client, unquote_splicing(required_args), [])
      end
    else
      @doc operation_doc
      def unquote(operation)(%Client{} = client, unquote_splicing(required_args)) do
        unquote(endpoint).unquote(operation)(client, unquote_splicing(required_args))
      end
    end

    case compatibility do
      {:positional, defaults} ->
        all_args = Macro.generate_arguments(required_count + length(defaults), __MODULE__)
        required_compat_args = Enum.take(all_args, required_count)
        optional_args = Enum.drop(all_args, required_count)

        for supplied_count <- 0..length(defaults) do
          supplied_args = Enum.take(optional_args, supplied_count)

          options =
            defaults
            |> Enum.with_index()
            |> Enum.map(fn {{key, default}, index} ->
              value = if index < supplied_count, do: Enum.at(optional_args, index), else: Macro.escape(default)
              {:{}, [], [key, value]}
            end)

          if supports_opts? do
            if (required_count + supplied_count) not in client_arities do
              @doc operation_doc
            end

            def unquote(operation)(unquote_splicing(required_compat_args ++ supplied_args)) do
              with_default_client(fn client ->
                unquote(endpoint).unquote(operation)(
                  client,
                  unquote_splicing(required_compat_args),
                  unquote(options)
                )
              end)
            end
          else
            if (required_count + supplied_count) not in client_arities do
              @doc operation_doc
            end

            def unquote(operation)(unquote_splicing(required_compat_args ++ supplied_args)) do
              with_default_client(fn client ->
                unquote(endpoint).unquote(operation)(client, unquote_splicing(required_compat_args))
              end)
            end
          end
        end

      :keyword ->
        def unquote(operation)(unquote_splicing(required_args), opts) when is_list(opts) do
          with_default_client(fn client ->
            unquote(endpoint).unquote(operation)(client, unquote_splicing(required_args), opts)
          end)
        end

        def unquote(operation)(unquote_splicing(required_args)) do
          with_default_client(fn client ->
            unquote(endpoint).unquote(operation)(client, unquote_splicing(required_args), [])
          end)
        end
    end
  end

  @doc "Deprecated alias for `get_collection/2` and `get_collection/1`."
  @deprecated "Use Qdrant.get_collection/2 with a client and options instead"
  @spec collection_info(Client.t(), String.t(), Types.request_options()) :: Types.result()
  def collection_info(%Client{} = client, collection_name, opts), do: get_collection(client, collection_name, opts)

  @doc "Deprecated alias for `get_collection/2`."
  @deprecated "Use Qdrant.get_collection/2 with a client instead"
  @spec collection_info(Client.t(), String.t()) :: Types.result()
  def collection_info(%Client{} = client, collection_name), do: get_collection(client, collection_name)

  @doc "Deprecated alias for `get_collection/1`."
  @deprecated "Use Qdrant.get_collection/1 instead"
  @spec collection_info(String.t()) :: Types.result()
  def collection_info(collection_name), do: get_collection(collection_name)

  @doc "Deprecated alias for `get_collection/2` and `get_collection/1`."
  @deprecated "Use Qdrant.get_collection/2 with a client and options instead"
  @spec get_collection_details(Client.t(), String.t(), Types.request_options()) :: Types.result()
  def get_collection_details(%Client{} = client, collection_name, opts),
    do: get_collection(client, collection_name, opts)

  @doc "Deprecated alias for `get_collection/2`."
  @deprecated "Use Qdrant.get_collection/2 with a client instead"
  @spec get_collection_details(Client.t(), String.t()) :: Types.result()
  def get_collection_details(%Client{} = client, collection_name), do: get_collection(client, collection_name)

  @doc "Deprecated alias for `get_collection/1`."
  @deprecated "Use Qdrant.get_collection/1 instead"
  @spec get_collection_details(String.t()) :: Types.result()
  def get_collection_details(collection_name), do: get_collection(collection_name)

  @doc "Deprecated alias for `upsert_points/4` and `upsert_points/3`."
  @deprecated "Use Qdrant.upsert_points/4 with a client and options instead"
  @spec upsert_point(
          Client.t() | String.t(),
          String.t() | Types.request_body(),
          Types.request_body() | boolean() | nil,
          Types.request_options() | Types.ordering() | nil
        ) :: Types.result()
  def upsert_point(%Client{} = client, collection_name, body, opts),
    do: upsert_points(client, collection_name, body, opts)

  def upsert_point(collection_name, body, wait, ordering),
    do: upsert_points(collection_name, body, wait, ordering)

  @doc "Deprecated alias for `upsert_points/3` and `upsert_points/2`."
  @deprecated "Use Qdrant.upsert_points/3 with a client instead"
  @spec upsert_point(
          Client.t() | String.t(),
          String.t() | Types.request_body(),
          Types.request_body() | boolean() | nil
        ) :: Types.result()
  def upsert_point(%Client{} = client, collection_name, body), do: upsert_points(client, collection_name, body)
  def upsert_point(collection_name, body, wait), do: upsert_points(collection_name, body, wait)

  @doc "Deprecated alias for `upsert_points/2`."
  @deprecated "Use Qdrant.upsert_points/2 instead"
  @spec upsert_point(String.t(), Types.request_body()) :: Types.result()
  def upsert_point(collection_name, body), do: upsert_points(collection_name, body)

  defp with_default_client(operation) do
    with {:ok, client} <- default_client() do
      operation.(client)
    end
  end
end
