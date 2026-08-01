# Qdrant Elixir Client

This library is under active development and subject to change. Use the latest
release for production applications.

An Elixir REST client targeting Qdrant 1.15.x. Successful calls preserve the
complete Qdrant response envelope as `{:ok, body}`. Failures return
`{:error, %Qdrant.Error{}}` with HTTP and response context where available.

gRPC is unsupported.

[![Hex.pm](https://img.shields.io/hexpm/v/qdrant.svg)](https://hex.pm/packages/qdrant) [![Hex.pm](https://img.shields.io/hexpm/dt/qdrant.svg)](https://hex.pm/packages/qdrant) [![Hex.pm](https://img.shields.io/hexpm/l/qdrant.svg)](https://hex.pm/packages/qdrant)

## Installation

The package is [available on Hex](https://hex.pm/packages/qdrant), with
documentation on [HexDocs](https://hexdocs.pm/qdrant/readme.html). Add it to
`mix.exs`:

```elixir
def deps do
  [
    {:qdrant, "~> 0.1.0"}
  ]
end
```

## Client Setup

Construct an explicit client for application code. A client retains its own
URL, credentials, adapter, and timeout settings, so one application can safely
connect to multiple Qdrant clusters.

```elixir
client =
  Qdrant.Client.new!(
    url: "https://cluster-id.cloud.qdrant.io:6333",
    api_key: System.fetch_env!("QDRANT_API_KEY")
  )
```

The production adapter is `Tesla.Adapter.Finch`, backed by the supervised
`Qdrant.Finch` pool. Defaults are a 30,000 ms receive timeout, 5,000 ms pool
timeout, and a 50 MiB maximum in-memory response.

Client options:

| Option | Default | Purpose |
|---|---|---|
| `:interface` | `:rest` | Protocol interface; gRPC is reserved for a future release |
| `:url` | `http://localhost:6333` | Full Qdrant base URL |
| `:api_key` | `nil` | Value for the `api-key` header |
| `:require_api_key` | Cloud-host detection | Reject a missing required key |
| `:allow_insecure_api_key` | `false` | Permit a key over remote plain HTTP |
| `:adapter` | `Tesla.Adapter.Finch` | Per-client Tesla adapter |
| `:adapter_opts` | Finch timeout/pool defaults | Adapter configuration |
| `:base_path` | `""` | Optional path below the base URL |
| `:max_response_bytes` | 50 MiB | Limit for in-memory responses |

API keys are rejected over plain HTTP to non-loopback hosts unless
`allow_insecure_api_key: true` is explicit. Hosts equal to `cloud.qdrant.io` or
ending in `.cloud.qdrant.io` require a key by default.

## Features

The client provides endpoint modules for:

* Collections and payload indexes
* Points, search, recommendation, discovery, and query operations
* Collection aliases
* Collection, full, and shard snapshots
* Cluster and service operations, including health checks and metrics

For the complete public API, see the [module documentation](https://hexdocs.pm/qdrant).

## Usage

New calls put the client first and use one final keyword options argument.

```elixir
collection = "articles"

{:ok, _} =
  Qdrant.create_collection(client, collection, %{
    vectors: %{size: 3, distance: "Cosine"}
  })

{:ok, _} =
  Qdrant.upsert_points(
    client,
    collection,
    %{points: [%{id: 1, vector: [0.1, 0.2, 0.3], payload: %{title: "First"}}]},
    wait: true,
    ordering: :strong
  )

{:ok, response} =
  Qdrant.query_points(
    client,
    collection,
    %{query: [0.1, 0.2, 0.3], limit: 10},
    consistency: :majority,
    timeout: 10
  )

points = response["result"]["points"]
```

Qdrant also accepts `%{query: %{nearest: vector}, limit: 10}`. The `query` key
may be omitted when Qdrant permits ID-ordered retrieval.

Batch search, recommendation, discovery, and query calls require the wire
wrapper `%{searches: [request, ...]}`. Payload clearing requires a selector such
as `%{points: [1, 2]}` or `%{filter: filter}`.

Use the download-to-file functions for large snapshots:

```elixir
{:ok, path} =
  Qdrant.download_snapshot_to_file(
    client,
    "articles",
    "snapshot.snapshot",
    "/var/backups/articles.snapshot"
  )
```

File-path snapshot uploads are streamed with
`Qdrant.recover_from_uploaded_snapshot_file/4`. Existing binary upload and
in-memory download forms remain available, with the configured response limit.

## Direct HTTP Module Access

The domain-specific HTTP modules remain available for callers that need direct
access. Client-first calls are preferred:

```elixir
client = Qdrant.Client.new!()

{:ok, _} = Qdrant.Api.Http.Collections.list_collections(client)

{:ok, _} =
  Qdrant.Api.Http.Points.search_points(
    client,
    "articles",
    %{vector: [0.1, 0.2, 0.3], limit: 3}
  )

{:ok, _} = Qdrant.Api.Http.Service.healthz(client)
```

## Architecture

Requests use Tesla with `Tesla.Adapter.Finch` in production. The supervised
`Qdrant.Finch` pool provides connection pooling and transport timeouts, while
shared request handling encodes paths and queries, parses responses, and
returns consistent `Qdrant.Error` values.

## Compatibility Configuration

No-client `Qdrant.*` functions remain available during the compatibility
period. They construct `Qdrant.default_client/0` for each call. Explicit clients
are preferred.

The compatibility URL precedence is exact:

1. Application `config :qdrant, url: ...`
2. Application `:database_url` plus application `:port`
3. `QDRANT_URL`
4. `QDRANT_DATABASE_URL` plus `QDRANT_PORT`
5. `http://localhost:6333`

Application `:api_key`, `:require_api_key`, and `:allow_insecure_api_key` take
precedence over `QDRANT_API_KEY`, `QDRANT_REQUIRE_API_KEY`, and
`QDRANT_ALLOW_INSECURE_API_KEY`. Environment booleans must be `true` or `false`,
and ports must be integers from 1 through 65535.

Supported environment variables include:

* `QDRANT_URL` - Full Qdrant server URL
* `QDRANT_DATABASE_URL` - Qdrant server URL without a port
* `QDRANT_PORT` - Qdrant server port
* `QDRANT_REQUIRE_API_KEY` - Whether an API key is required
* `QDRANT_API_KEY` - API key for authentication
* `QDRANT_ALLOW_INSECURE_API_KEY` - Allow API keys over remote plain HTTP

```elixir
config :qdrant,
  interface: :rest,
  url: "http://localhost:6333",
  require_api_key: false
```

The older `collection_info`, `get_collection_details`, and `upsert_point`
names are deprecated. Use `get_collection` and `upsert_points`.

## Development

```bash
mix deps.get
mix format --check-formatted
mix compile --warnings-as-errors
mix test
mix dialyzer
mix docs
mix hex.build
```

Integration tests are opt-in and expect Qdrant 1.15.x at `QDRANT_URL`:

```bash
QDRANT_INTEGRATION=true QDRANT_URL=http://127.0.0.1:6333 mix test --only integration
```

## Contributing

* Fork the repository
* Create a branch for your changes
* Run `mix format` and `mix test`
* Submit a pull request

## Changelog

See [CHANGELOG.md](CHANGELOG.md). Generate the changelog with:

```bash
git-chglog -o CHANGELOG.md
```

## License

MIT. See [LICENSE](LICENSE).
