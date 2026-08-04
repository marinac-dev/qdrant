defmodule Qdrant.Api.Http.Snapshots do
  @moduledoc """
  Qdrant snapshot backup, recovery, upload, and download operations.

  Functions accepting a `Qdrant.Client` are the canonical API. Calls without a
  client remain available for compatibility and use the application configuration.
  """

  alias Qdrant.Api.Http.Request
  alias Qdrant.{Client, Config, Error, Types}

  # Collection snapshots

  @spec list_snapshots(Client.t(), String.t(), Types.request_options()) :: Types.result()
  def list_snapshots(%Client{} = client, collection_name, opts) when is_list(opts) do
    Request.request(client, :get, collection_snapshots_path(collection_name), response: :json)
  end

  @spec list_snapshots(Client.t(), String.t()) :: Types.result()
  def list_snapshots(%Client{} = client, collection_name), do: list_snapshots(client, collection_name, [])

  @spec list_snapshots(String.t()) :: Types.result()
  def list_snapshots(collection_name), do: with_default_client(&list_snapshots(&1, collection_name, []))

  @spec create_snapshot(Client.t(), String.t(), Types.request_options()) :: Types.result()
  def create_snapshot(%Client{} = client, collection_name, opts) when is_list(opts) do
    Request.request(client, :post, collection_snapshots_path(collection_name),
      query: [wait: opts[:wait]],
      body: %{},
      response: :json
    )
  end

  @spec create_snapshot(Client.t(), String.t()) :: Types.result()
  def create_snapshot(%Client{} = client, collection_name), do: create_snapshot(client, collection_name, [])

  @spec create_snapshot(String.t(), boolean() | nil) :: Types.result()
  def create_snapshot(collection_name, wait),
    do: with_default_client(&create_snapshot(&1, collection_name, wait: wait))

  @spec create_snapshot(String.t()) :: Types.result()
  def create_snapshot(collection_name), do: create_snapshot(collection_name, nil)

  @doc "Returns the collection snapshot contents as a bounded in-memory binary."
  @spec get_snapshot(Client.t(), String.t(), String.t(), Types.request_options()) :: Types.result()
  def get_snapshot(%Client{} = client, collection_name, snapshot_name, opts) when is_list(opts) do
    Request.request(client, :get, collection_snapshot_path(collection_name, snapshot_name), response: :binary)
  end

  @spec get_snapshot(Client.t(), String.t(), String.t()) :: Types.result()
  def get_snapshot(%Client{} = client, collection_name, snapshot_name),
    do: get_snapshot(client, collection_name, snapshot_name, [])

  @spec get_snapshot(String.t(), String.t()) :: Types.result()
  def get_snapshot(collection_name, snapshot_name),
    do: with_default_client(&get_snapshot(&1, collection_name, snapshot_name, []))

  @doc "Streams a collection snapshot to `destination`."
  @spec download_snapshot_to_file(Client.t(), String.t(), String.t(), Path.t(), Types.request_options()) ::
          {:ok, Path.t()} | {:error, Error.t()}
  def download_snapshot_to_file(%Client{} = client, collection_name, snapshot_name, destination, opts)
      when is_list(opts) do
    download_to_file(client, collection_snapshot_path(collection_name, snapshot_name), destination)
  end

  @spec download_snapshot_to_file(Client.t(), String.t(), String.t(), Path.t()) ::
          {:ok, Path.t()} | {:error, Error.t()}
  def download_snapshot_to_file(%Client{} = client, collection_name, snapshot_name, destination),
    do: download_snapshot_to_file(client, collection_name, snapshot_name, destination, [])

  @spec download_snapshot_to_file(String.t(), String.t(), Path.t(), Types.request_options()) ::
          {:ok, Path.t()} | {:error, Error.t()}
  def download_snapshot_to_file(collection_name, snapshot_name, destination, opts) when is_list(opts),
    do: with_default_client(&download_snapshot_to_file(&1, collection_name, snapshot_name, destination, opts))

  @spec download_snapshot_to_file(String.t(), String.t(), Path.t()) ::
          {:ok, Path.t()} | {:error, Error.t()}
  def download_snapshot_to_file(collection_name, snapshot_name, destination),
    do: download_snapshot_to_file(collection_name, snapshot_name, destination, [])

  @spec delete_snapshot(Client.t(), String.t(), String.t(), Types.request_options()) :: Types.result()
  def delete_snapshot(%Client{} = client, collection_name, snapshot_name, opts) when is_list(opts) do
    Request.request(client, :delete, collection_snapshot_path(collection_name, snapshot_name),
      query: [wait: opts[:wait]],
      response: :json
    )
  end

  @spec delete_snapshot(Client.t(), String.t(), String.t()) :: Types.result()
  def delete_snapshot(%Client{} = client, collection_name, snapshot_name),
    do: delete_snapshot(client, collection_name, snapshot_name, [])

  @spec delete_snapshot(String.t(), String.t(), boolean() | nil) :: Types.result()
  def delete_snapshot(collection_name, snapshot_name, wait),
    do: with_default_client(&delete_snapshot(&1, collection_name, snapshot_name, wait: wait))

  @spec delete_snapshot(String.t(), String.t()) :: Types.result()
  def delete_snapshot(collection_name, snapshot_name), do: delete_snapshot(collection_name, snapshot_name, nil)

  @spec recover_from_snapshot(Client.t(), String.t(), Types.request_body(), Types.request_options()) :: Types.result()
  def recover_from_snapshot(%Client{} = client, collection_name, body, opts) when is_list(opts) do
    Request.request(client, :put, collection_snapshots_path(collection_name) <> "/recover",
      query: [wait: opts[:wait], priority: opts[:priority]],
      body: body,
      response: :json
    )
  end

  @spec recover_from_snapshot(String.t(), Types.request_body(), boolean() | nil, String.t() | nil) :: Types.result()
  def recover_from_snapshot(collection_name, body, wait, priority),
    do: with_default_client(&recover_from_snapshot(&1, collection_name, body, wait: wait, priority: priority))

  @spec recover_from_snapshot(Client.t(), String.t(), Types.request_body()) :: Types.result()
  def recover_from_snapshot(%Client{} = client, collection_name, body),
    do: recover_from_snapshot(client, collection_name, body, [])

  @spec recover_from_snapshot(
          String.t(),
          Types.request_body(),
          Types.request_options() | boolean() | nil
        ) :: Types.result()
  def recover_from_snapshot(collection_name, body, opts) when is_list(opts),
    do: with_default_client(&recover_from_snapshot(&1, collection_name, body, opts))

  def recover_from_snapshot(collection_name, body, wait),
    do: recover_from_snapshot(collection_name, body, wait, nil)

  @spec recover_from_snapshot(String.t(), Types.request_body()) :: Types.result()
  def recover_from_snapshot(collection_name, body), do: recover_from_snapshot(collection_name, body, nil, nil)

  @doc """
  Recovers a collection from uploaded snapshot data.

  Binary data is uploaded with multipart field `snapshot`. Set `source: :file`
  to stream a path, or use `recover_from_uploaded_snapshot_file/4`. The
  multipart filename can be overridden with `:filename`.
  """
  @spec recover_from_uploaded_snapshot(Client.t(), String.t(), binary(), Types.request_options()) :: Types.result()
  def recover_from_uploaded_snapshot(%Client{} = client, collection_name, snapshot_data, opts)
      when is_list(opts) do
    multipart = snapshot_multipart(snapshot_data, opts)

    Request.request(client, :post, collection_snapshots_path(collection_name) <> "/upload",
      query: [wait: opts[:wait], priority: opts[:priority], checksum: opts[:checksum]],
      body: multipart,
      response: :json
    )
  end

  @spec recover_from_uploaded_snapshot(String.t(), binary(), boolean() | nil, String.t() | nil) :: Types.result()
  def recover_from_uploaded_snapshot(collection_name, snapshot_data, wait, priority),
    do: recover_from_uploaded_snapshot(collection_name, snapshot_data, wait, priority, nil)

  @spec recover_from_uploaded_snapshot(String.t(), binary(), boolean() | nil, String.t() | nil, String.t() | nil) ::
          Types.result()
  def recover_from_uploaded_snapshot(collection_name, snapshot_data, wait, priority, checksum),
    do:
      with_default_client(
        &recover_from_uploaded_snapshot(&1, collection_name, snapshot_data,
          wait: wait,
          priority: priority,
          checksum: checksum
        )
      )

  @spec recover_from_uploaded_snapshot(Client.t(), String.t(), binary()) :: Types.result()
  def recover_from_uploaded_snapshot(%Client{} = client, collection_name, snapshot_data),
    do: recover_from_uploaded_snapshot(client, collection_name, snapshot_data, [])

  @spec recover_from_uploaded_snapshot(String.t(), binary(), Types.request_options() | boolean() | nil) ::
          Types.result()
  def recover_from_uploaded_snapshot(collection_name, snapshot_data, opts) when is_list(opts),
    do: with_default_client(&recover_from_uploaded_snapshot(&1, collection_name, snapshot_data, opts))

  def recover_from_uploaded_snapshot(collection_name, snapshot_data, wait),
    do: recover_from_uploaded_snapshot(collection_name, snapshot_data, wait, nil, nil)

  @spec recover_from_uploaded_snapshot(String.t(), binary()) :: Types.result()
  def recover_from_uploaded_snapshot(collection_name, snapshot_data),
    do: recover_from_uploaded_snapshot(collection_name, snapshot_data, nil, nil, nil)

  @spec recover_from_uploaded_snapshot_file(Client.t(), String.t(), Path.t(), Types.request_options()) :: Types.result()
  def recover_from_uploaded_snapshot_file(%Client{} = client, collection_name, path, opts) when is_list(opts),
    do: recover_from_uploaded_snapshot(client, collection_name, path, Keyword.put(opts, :source, :file))

  @spec recover_from_uploaded_snapshot_file(Client.t(), String.t(), Path.t()) :: Types.result()
  def recover_from_uploaded_snapshot_file(%Client{} = client, collection_name, path),
    do: recover_from_uploaded_snapshot_file(client, collection_name, path, [])

  @spec recover_from_uploaded_snapshot_file(String.t(), Path.t(), Types.request_options()) :: Types.result()
  def recover_from_uploaded_snapshot_file(collection_name, path, opts) when is_list(opts),
    do: with_default_client(&recover_from_uploaded_snapshot_file(&1, collection_name, path, opts))

  @spec recover_from_uploaded_snapshot_file(String.t(), Path.t()) :: Types.result()
  def recover_from_uploaded_snapshot_file(collection_name, path),
    do: recover_from_uploaded_snapshot_file(collection_name, path, [])

  # Full snapshots

  @spec list_full_snapshots(Client.t(), Types.request_options()) :: Types.result()
  def list_full_snapshots(%Client{} = client, opts) when is_list(opts),
    do: Request.request(client, :get, "/snapshots", response: :json)

  @spec list_full_snapshots(Client.t()) :: Types.result()
  def list_full_snapshots(%Client{} = client), do: list_full_snapshots(client, [])

  @spec list_full_snapshots(Types.request_options()) :: Types.result()
  def list_full_snapshots(opts) when is_list(opts), do: with_default_client(&list_full_snapshots(&1, opts))

  @spec list_full_snapshots() :: Types.result()
  def list_full_snapshots, do: with_default_client(&list_full_snapshots(&1, []))

  @spec create_full_snapshot(Client.t(), Types.request_options()) :: Types.result()
  def create_full_snapshot(%Client{} = client, opts) when is_list(opts) do
    Request.request(client, :post, "/snapshots", query: [wait: opts[:wait]], body: %{}, response: :json)
  end

  @spec create_full_snapshot(Client.t()) :: Types.result()
  def create_full_snapshot(%Client{} = client), do: create_full_snapshot(client, [])

  @spec create_full_snapshot(Types.request_options() | boolean() | nil) :: Types.result()
  def create_full_snapshot(opts) when is_list(opts), do: with_default_client(&create_full_snapshot(&1, opts))
  def create_full_snapshot(wait), do: with_default_client(&create_full_snapshot(&1, wait: wait))

  @spec create_full_snapshot() :: Types.result()
  def create_full_snapshot, do: create_full_snapshot(nil)

  @doc "Returns the full snapshot contents as a bounded in-memory binary."
  @spec get_full_snapshot(Client.t(), String.t(), Types.request_options()) :: Types.result()
  def get_full_snapshot(%Client{} = client, snapshot_name, opts) when is_list(opts),
    do: Request.request(client, :get, full_snapshot_path(snapshot_name), response: :binary)

  @spec get_full_snapshot(Client.t(), String.t()) :: Types.result()
  def get_full_snapshot(%Client{} = client, snapshot_name), do: get_full_snapshot(client, snapshot_name, [])

  @spec get_full_snapshot(String.t()) :: Types.result()
  def get_full_snapshot(snapshot_name), do: with_default_client(&get_full_snapshot(&1, snapshot_name, []))

  @doc "Streams a full snapshot to `destination`."
  @spec download_full_snapshot_to_file(Client.t(), String.t(), Path.t(), Types.request_options()) ::
          {:ok, Path.t()} | {:error, Error.t()}
  def download_full_snapshot_to_file(%Client{} = client, snapshot_name, destination, opts) when is_list(opts),
    do: download_to_file(client, full_snapshot_path(snapshot_name), destination)

  @spec download_full_snapshot_to_file(Client.t(), String.t(), Path.t()) ::
          {:ok, Path.t()} | {:error, Error.t()}
  def download_full_snapshot_to_file(%Client{} = client, snapshot_name, destination),
    do: download_full_snapshot_to_file(client, snapshot_name, destination, [])

  @spec download_full_snapshot_to_file(String.t(), Path.t(), Types.request_options()) ::
          {:ok, Path.t()} | {:error, Error.t()}
  def download_full_snapshot_to_file(snapshot_name, destination, opts) when is_list(opts),
    do: with_default_client(&download_full_snapshot_to_file(&1, snapshot_name, destination, opts))

  @spec download_full_snapshot_to_file(String.t(), Path.t()) ::
          {:ok, Path.t()} | {:error, Error.t()}
  def download_full_snapshot_to_file(snapshot_name, destination),
    do: download_full_snapshot_to_file(snapshot_name, destination, [])

  @spec delete_full_snapshot(Client.t(), String.t(), Types.request_options()) :: Types.result()
  def delete_full_snapshot(%Client{} = client, snapshot_name, opts) when is_list(opts) do
    Request.request(client, :delete, full_snapshot_path(snapshot_name),
      query: [wait: opts[:wait]],
      response: :json
    )
  end

  @spec delete_full_snapshot(Client.t(), String.t()) :: Types.result()
  def delete_full_snapshot(%Client{} = client, snapshot_name), do: delete_full_snapshot(client, snapshot_name, [])

  @spec delete_full_snapshot(String.t(), boolean() | nil) :: Types.result()
  def delete_full_snapshot(snapshot_name, wait),
    do: with_default_client(&delete_full_snapshot(&1, snapshot_name, wait: wait))

  @spec delete_full_snapshot(String.t()) :: Types.result()
  def delete_full_snapshot(snapshot_name), do: delete_full_snapshot(snapshot_name, nil)

  # Shard snapshots

  @spec list_shard_snapshots(Client.t(), String.t(), integer(), Types.request_options()) :: Types.result()
  def list_shard_snapshots(%Client{} = client, collection_name, shard_id, opts) when is_list(opts) do
    Request.request(client, :get, shard_snapshots_path(collection_name, shard_id), response: :json)
  end

  @spec list_shard_snapshots(Client.t(), String.t(), integer()) :: Types.result()
  def list_shard_snapshots(%Client{} = client, collection_name, shard_id),
    do: list_shard_snapshots(client, collection_name, shard_id, [])

  @spec list_shard_snapshots(String.t(), integer()) :: Types.result()
  def list_shard_snapshots(collection_name, shard_id),
    do: with_default_client(&list_shard_snapshots(&1, collection_name, shard_id, []))

  @spec create_shard_snapshot(Client.t(), String.t(), integer(), Types.request_options()) :: Types.result()
  def create_shard_snapshot(%Client{} = client, collection_name, shard_id, opts) when is_list(opts) do
    Request.request(client, :post, shard_snapshots_path(collection_name, shard_id),
      query: [wait: opts[:wait]],
      body: %{},
      response: :json
    )
  end

  @spec create_shard_snapshot(Client.t(), String.t(), integer()) :: Types.result()
  def create_shard_snapshot(%Client{} = client, collection_name, shard_id),
    do: create_shard_snapshot(client, collection_name, shard_id, [])

  @spec create_shard_snapshot(String.t(), integer(), boolean() | nil) :: Types.result()
  def create_shard_snapshot(collection_name, shard_id, wait),
    do: with_default_client(&create_shard_snapshot(&1, collection_name, shard_id, wait: wait))

  @spec create_shard_snapshot(String.t(), integer()) :: Types.result()
  def create_shard_snapshot(collection_name, shard_id), do: create_shard_snapshot(collection_name, shard_id, nil)

  @doc "Returns the shard snapshot contents as a bounded in-memory binary."
  @spec get_shard_snapshot(Client.t(), String.t(), integer(), String.t(), Types.request_options()) :: Types.result()
  def get_shard_snapshot(%Client{} = client, collection_name, shard_id, snapshot_name, opts) when is_list(opts) do
    Request.request(client, :get, shard_snapshot_path(collection_name, shard_id, snapshot_name), response: :binary)
  end

  @spec get_shard_snapshot(Client.t(), String.t(), integer(), String.t()) :: Types.result()
  def get_shard_snapshot(%Client{} = client, collection_name, shard_id, snapshot_name),
    do: get_shard_snapshot(client, collection_name, shard_id, snapshot_name, [])

  @spec get_shard_snapshot(String.t(), integer(), String.t()) :: Types.result()
  def get_shard_snapshot(collection_name, shard_id, snapshot_name),
    do: with_default_client(&get_shard_snapshot(&1, collection_name, shard_id, snapshot_name, []))

  @doc "Streams the current state of a shard as a bounded in-memory snapshot binary."
  @spec stream_shard_snapshot(Client.t(), String.t(), integer()) :: Types.result(binary())
  def stream_shard_snapshot(%Client{} = client, collection_name, shard_id) do
    Request.request(client, :get, shard_stream_snapshot_path(collection_name, shard_id), response: :binary)
  end

  @spec stream_shard_snapshot(String.t(), integer()) :: Types.result(binary())
  def stream_shard_snapshot(collection_name, shard_id),
    do: with_default_client(&stream_shard_snapshot(&1, collection_name, shard_id))

  @doc "Streams a shard snapshot to `destination`."
  @spec download_shard_snapshot_to_file(
          Client.t(),
          String.t(),
          integer(),
          String.t(),
          Path.t(),
          Types.request_options()
        ) ::
          {:ok, Path.t()} | {:error, Error.t()}
  def download_shard_snapshot_to_file(
        %Client{} = client,
        collection_name,
        shard_id,
        snapshot_name,
        destination,
        opts
      )
      when is_list(opts) do
    download_to_file(client, shard_snapshot_path(collection_name, shard_id, snapshot_name), destination)
  end

  @spec download_shard_snapshot_to_file(Client.t(), String.t(), integer(), String.t(), Path.t()) ::
          {:ok, Path.t()} | {:error, Error.t()}
  def download_shard_snapshot_to_file(%Client{} = client, collection_name, shard_id, snapshot_name, destination),
    do: download_shard_snapshot_to_file(client, collection_name, shard_id, snapshot_name, destination, [])

  @spec download_shard_snapshot_to_file(
          String.t(),
          integer(),
          String.t(),
          Path.t(),
          Types.request_options()
        ) ::
          {:ok, Path.t()} | {:error, Error.t()}
  def download_shard_snapshot_to_file(collection_name, shard_id, snapshot_name, destination, opts)
      when is_list(opts),
      do:
        with_default_client(
          &download_shard_snapshot_to_file(&1, collection_name, shard_id, snapshot_name, destination, opts)
        )

  @spec download_shard_snapshot_to_file(String.t(), integer(), String.t(), Path.t()) ::
          {:ok, Path.t()} | {:error, Error.t()}
  def download_shard_snapshot_to_file(collection_name, shard_id, snapshot_name, destination),
    do: download_shard_snapshot_to_file(collection_name, shard_id, snapshot_name, destination, [])

  @spec delete_shard_snapshot(
          Client.t(),
          String.t(),
          integer(),
          String.t(),
          Types.request_options()
        ) :: Types.result()
  def delete_shard_snapshot(%Client{} = client, collection_name, shard_id, snapshot_name, opts) when is_list(opts) do
    Request.request(client, :delete, shard_snapshot_path(collection_name, shard_id, snapshot_name),
      query: [wait: opts[:wait]],
      response: :json
    )
  end

  @spec delete_shard_snapshot(Client.t(), String.t(), integer(), String.t()) :: Types.result()
  def delete_shard_snapshot(%Client{} = client, collection_name, shard_id, snapshot_name),
    do: delete_shard_snapshot(client, collection_name, shard_id, snapshot_name, [])

  @spec delete_shard_snapshot(String.t(), integer(), String.t(), boolean() | nil) :: Types.result()
  def delete_shard_snapshot(collection_name, shard_id, snapshot_name, wait),
    do: with_default_client(&delete_shard_snapshot(&1, collection_name, shard_id, snapshot_name, wait: wait))

  @spec delete_shard_snapshot(String.t(), integer(), String.t()) :: Types.result()
  def delete_shard_snapshot(collection_name, shard_id, snapshot_name),
    do: delete_shard_snapshot(collection_name, shard_id, snapshot_name, nil)

  @spec recover_shard_from_snapshot(
          Client.t(),
          String.t(),
          integer(),
          Types.request_body(),
          Types.request_options()
        ) :: Types.result()
  def recover_shard_from_snapshot(%Client{} = client, collection_name, shard_id, body, opts) when is_list(opts) do
    Request.request(client, :put, shard_snapshots_path(collection_name, shard_id) <> "/recover",
      query: [wait: opts[:wait], priority: opts[:priority]],
      body: body,
      response: :json
    )
  end

  @spec recover_shard_from_snapshot(String.t(), integer(), Types.request_body(), boolean() | nil, String.t() | nil) ::
          Types.result()
  def recover_shard_from_snapshot(collection_name, shard_id, body, wait, priority),
    do:
      with_default_client(
        &recover_shard_from_snapshot(&1, collection_name, shard_id, body, wait: wait, priority: priority)
      )

  @spec recover_shard_from_snapshot(Client.t(), String.t(), integer(), Types.request_body()) :: Types.result()
  def recover_shard_from_snapshot(%Client{} = client, collection_name, shard_id, body),
    do: recover_shard_from_snapshot(client, collection_name, shard_id, body, [])

  @spec recover_shard_from_snapshot(
          String.t(),
          integer(),
          Types.request_body(),
          Types.request_options() | boolean() | nil
        ) :: Types.result()
  def recover_shard_from_snapshot(collection_name, shard_id, body, opts) when is_list(opts),
    do: with_default_client(&recover_shard_from_snapshot(&1, collection_name, shard_id, body, opts))

  def recover_shard_from_snapshot(collection_name, shard_id, body, wait),
    do: recover_shard_from_snapshot(collection_name, shard_id, body, wait, nil)

  @spec recover_shard_from_snapshot(String.t(), integer(), Types.request_body()) :: Types.result()
  def recover_shard_from_snapshot(collection_name, shard_id, body),
    do: recover_shard_from_snapshot(collection_name, shard_id, body, nil, nil)

  @doc """
  Recovers a shard from uploaded snapshot data.

  Supports binary data and streamed paths in the same way as
  `recover_from_uploaded_snapshot/4`, including `:filename` and `:checksum`.
  """
  @spec recover_shard_from_uploaded_snapshot(
          Client.t(),
          String.t(),
          integer(),
          binary(),
          Types.request_options()
        ) :: Types.result()
  def recover_shard_from_uploaded_snapshot(%Client{} = client, collection_name, shard_id, snapshot_data, opts)
      when is_list(opts) do
    multipart = snapshot_multipart(snapshot_data, opts)

    Request.request(client, :post, shard_snapshots_path(collection_name, shard_id) <> "/upload",
      query: [wait: opts[:wait], priority: opts[:priority], checksum: opts[:checksum]],
      body: multipart,
      response: :json
    )
  end

  @spec recover_shard_from_uploaded_snapshot(String.t(), integer(), binary(), boolean() | nil, String.t() | nil) ::
          Types.result()
  def recover_shard_from_uploaded_snapshot(collection_name, shard_id, snapshot_data, wait, priority),
    do: recover_shard_from_uploaded_snapshot(collection_name, shard_id, snapshot_data, wait, priority, nil)

  @spec recover_shard_from_uploaded_snapshot(
          String.t(),
          integer(),
          binary(),
          boolean() | nil,
          String.t() | nil,
          String.t() | nil
        ) :: Types.result()
  def recover_shard_from_uploaded_snapshot(collection_name, shard_id, snapshot_data, wait, priority, checksum),
    do:
      with_default_client(
        &recover_shard_from_uploaded_snapshot(&1, collection_name, shard_id, snapshot_data,
          wait: wait,
          priority: priority,
          checksum: checksum
        )
      )

  @spec recover_shard_from_uploaded_snapshot(Client.t(), String.t(), integer(), binary()) :: Types.result()
  def recover_shard_from_uploaded_snapshot(%Client{} = client, collection_name, shard_id, snapshot_data),
    do: recover_shard_from_uploaded_snapshot(client, collection_name, shard_id, snapshot_data, [])

  @spec recover_shard_from_uploaded_snapshot(
          String.t(),
          integer(),
          binary(),
          Types.request_options() | boolean() | nil
        ) :: Types.result()
  def recover_shard_from_uploaded_snapshot(collection_name, shard_id, snapshot_data, opts) when is_list(opts),
    do: with_default_client(&recover_shard_from_uploaded_snapshot(&1, collection_name, shard_id, snapshot_data, opts))

  def recover_shard_from_uploaded_snapshot(collection_name, shard_id, snapshot_data, wait),
    do: recover_shard_from_uploaded_snapshot(collection_name, shard_id, snapshot_data, wait, nil, nil)

  @spec recover_shard_from_uploaded_snapshot(String.t(), integer(), binary()) :: Types.result()
  def recover_shard_from_uploaded_snapshot(collection_name, shard_id, snapshot_data),
    do: recover_shard_from_uploaded_snapshot(collection_name, shard_id, snapshot_data, nil, nil, nil)

  @spec recover_shard_from_uploaded_snapshot_file(
          Client.t(),
          String.t(),
          integer(),
          Path.t(),
          Types.request_options()
        ) :: Types.result()
  def recover_shard_from_uploaded_snapshot_file(%Client{} = client, collection_name, shard_id, path, opts)
      when is_list(opts),
      do:
        recover_shard_from_uploaded_snapshot(client, collection_name, shard_id, path, Keyword.put(opts, :source, :file))

  @spec recover_shard_from_uploaded_snapshot_file(Client.t(), String.t(), integer(), Path.t()) :: Types.result()
  def recover_shard_from_uploaded_snapshot_file(%Client{} = client, collection_name, shard_id, path),
    do: recover_shard_from_uploaded_snapshot_file(client, collection_name, shard_id, path, [])

  @spec recover_shard_from_uploaded_snapshot_file(
          String.t(),
          integer(),
          Path.t(),
          Types.request_options()
        ) :: Types.result()
  def recover_shard_from_uploaded_snapshot_file(collection_name, shard_id, path, opts) when is_list(opts),
    do: with_default_client(&recover_shard_from_uploaded_snapshot_file(&1, collection_name, shard_id, path, opts))

  @spec recover_shard_from_uploaded_snapshot_file(String.t(), integer(), Path.t()) :: Types.result()
  def recover_shard_from_uploaded_snapshot_file(collection_name, shard_id, path),
    do: recover_shard_from_uploaded_snapshot_file(collection_name, shard_id, path, [])

  defp snapshot_multipart(snapshot_data, opts) do
    multipart = Tesla.Multipart.new()

    if opts[:source] in [:file, :path] do
      file_opts = [name: "snapshot"]
      file_opts = if opts[:filename], do: Keyword.put(file_opts, :filename, opts[:filename]), else: file_opts
      Tesla.Multipart.add_file(multipart, snapshot_data, file_opts)
    else
      Tesla.Multipart.add_file_content(multipart, snapshot_data, opts[:filename] || "snapshot", name: "snapshot")
    end
  end

  defp collection_snapshots_path(collection_name), do: "/collections/#{Request.segment(collection_name)}/snapshots"

  defp collection_snapshot_path(collection_name, snapshot_name),
    do: collection_snapshots_path(collection_name) <> "/#{Request.segment(snapshot_name)}"

  defp full_snapshot_path(snapshot_name), do: "/snapshots/#{Request.segment(snapshot_name)}"

  defp shard_snapshots_path(collection_name, shard_id),
    do: "/collections/#{Request.segment(collection_name)}/shards/#{Request.segment(shard_id)}/snapshots"

  defp shard_snapshot_path(collection_name, shard_id, snapshot_name),
    do: shard_snapshots_path(collection_name, shard_id) <> "/#{Request.segment(snapshot_name)}"

  defp shard_stream_snapshot_path(collection_name, shard_id),
    do: "/collections/#{Request.segment(collection_name)}/shards/#{Request.segment(shard_id)}/snapshot"

  defp download_to_file(%Client{} = client, path, destination) do
    url = client.url <> client.base_path <> path

    result =
      Client.execute(client,
        method: :get,
        url: path,
        opts: [adapter: [response: :stream]]
      )

    case result do
      {:ok, %Tesla.Env{status: status, body: body}} when status in 200..299 ->
        write_download(body, destination, url)

      {:ok, %Tesla.Env{} = env} ->
        cleanup_destination(destination)
        {:error, http_error(env, url)}

      {:error, reason} ->
        cleanup_destination(destination)
        {:error, %Error{kind: :transport, reason: reason, method: :get, url: url}}
    end
  rescue
    exception ->
      cleanup_destination(destination)
      {:error, %Error{kind: :file, reason: exception, method: :get, url: client.url <> client.base_path <> path}}
  catch
    kind, reason ->
      cleanup_destination(destination)
      {:error, %Error{kind: :file, reason: {kind, reason}, method: :get, url: client.url <> client.base_path <> path}}
  end

  defp write_download(body, destination, url) do
    result =
      File.open(destination, [:write, :binary], fn file ->
        cond do
          is_binary(body) -> IO.binwrite(file, body)
          is_function(body, 2) -> write_stream_body(file, body)
          Enumerable.impl_for(body) -> Enum.reduce_while(body, :ok, &write_chunk(file, &1, &2))
          true -> {:error, {:unsupported_stream_body, body}}
        end
      end)

    case result do
      {:ok, :ok} ->
        {:ok, destination}

      {:ok, {:error, reason}} ->
        cleanup_destination(destination)
        {:error, %Error{kind: :file, reason: reason, method: :get, url: url}}

      {:error, reason} ->
        cleanup_destination(destination)
        {:error, %Error{kind: :file, reason: reason, method: :get, url: url}}
    end
  rescue
    exception ->
      cleanup_destination(destination)
      {:error, %Error{kind: :file, reason: exception, method: :get, url: url}}
  catch
    kind, reason ->
      cleanup_destination(destination)
      {:error, %Error{kind: :file, reason: {kind, reason}, method: :get, url: url}}
  end

  defp write_chunk(file, chunk, _acc) do
    :ok = IO.binwrite(file, chunk)
    {:cont, :ok}
  end

  defp write_stream_body(file, body) do
    case body.({:cont, :ok}, fn chunk, :ok ->
           :ok = IO.binwrite(file, chunk)
           {:cont, :ok}
         end) do
      {:done, :ok} -> :ok
      other -> {:error, {:stream, other}}
    end
  end

  defp http_error(env, url) do
    headers = Enum.map(env.headers, fn {name, value} -> {String.downcase(name), value} end)

    %Error{
      kind: :http,
      status: env.status,
      body: env.body,
      method: :get,
      url: url,
      headers: headers,
      request_id: request_id(headers)
    }
  end

  defp request_id(headers) do
    Enum.find_value(["x-request-id", "x-qdrant-request-id", "trace-id", "x-trace-id"], fn name ->
      case List.keyfind(headers, name, 0) do
        {^name, value} -> value
        nil -> nil
      end
    end)
  end

  defp cleanup_destination(destination) do
    case File.rm(destination) do
      :ok -> :ok
      {:error, :enoent} -> :ok
      {:error, _reason} -> :ok
    end
  end

  defp with_default_client(fun) do
    with {:ok, opts} <- Config.client_options(),
         {:ok, client} <- Client.new(opts) do
      fun.(client)
    end
  end
end
