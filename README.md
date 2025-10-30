# Qdrant Elixir Client

## ⚠️ This library is under active development and is subject to change. Please use the latest version from GitHub ⚠️

An Elixir client for the Qdrant vector similarity search engine. This library provides a convenient way to interact with the Qdrant API, offering functionality to create collections, insert vectors, search, delete data, and more.

[![Hex.pm](https://img.shields.io/hexpm/v/qdrant.svg)](https://hex.pm/packages/qdrant) [![Hex.pm](https://img.shields.io/hexpm/dt/qdrant.svg)](https://hex.pm/packages/qdrant) [![Hex.pm](https://img.shields.io/hexpm/l/qdrant.svg)](https://hex.pm/packages/qdrant)

## Installation

It's [available in Hex](https://hexdocs.pm/qdrant/readme.html), the package can be installed
by adding `qdrant` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:qdrant, "~> 0.8.0"}
    # Or use the latest version from GitHub | Recommended during development phase
    {:qdrant, github: "marinac-dev/qdrant.git", branch: "master"},
  ]
end
```

## Configuration

Configure the Qdrant client in your `config/config.exs`:

### Local/Docker Setup (Default)

```elixir
config :qdrant,
  interface: "rest", # gRPC not yet supported
  # Option 1: Use full URL (recommended)
  url: System.get_env("QDRANT_URL") || "http://localhost:6333",
  # Option 2: Use separate URL and port (for backward compatibility)
  # database_url: System.get_env("QDRANT_DATABASE_URL") || "http://localhost",
  # port: 6333,
  require_api_key: false  # Default: false for local/docker instances
```

### Qdrant Cloud Setup

```elixir
config :qdrant,
  interface: "rest",
  url: System.get_env("QDRANT_URL"),  # e.g., "https://your-cluster.cloud.qdrant.io"
  require_api_key: true,  # Required for Qdrant Cloud (auto-detected if URL contains cloud.qdrant.io)
  api_key: System.get_env("QDRANT_API_KEY")  # Required when require_api_key is true
```

**Note:** The client automatically detects Qdrant Cloud instances and requires an API key when:
- The URL contains `cloud.qdrant.io`, or
- The URL uses HTTPS and is not localhost

You can also explicitly set `require_api_key: true` to force API key authentication.

Alternatively, you can set these via environment variables:
- `QDRANT_URL` - Full Qdrant server URL (e.g., `http://localhost:6333`) - takes priority if set
- `QDRANT_DATABASE_URL` - Qdrant server URL without port (default: `http://localhost`)
- `QDRANT_PORT` - Qdrant server port (default: `6333`)
- `QDRANT_REQUIRE_API_KEY` - Whether API key is required (default: `false`, auto-detected for Qdrant Cloud)
- `QDRANT_API_KEY` - API key for authentication (required if `require_api_key` is true)

**Configuration priority:** Application config takes priority over environment variables.

## Usage

The Qdrant Elixir Client provides a simple interface for interacting with the Qdrant API.

### Collections

```elixir
collection_name = "my-collection"

# Create a new collection
# The vectors are 1536-dimensional (for OpenAI embeddings) and use the Cosine distance metric
{:ok, _} = Qdrant.create_collection(collection_name, %{
  vectors: %{
    size: 1536,
    distance: "Cosine"
  }
})

# List all collections
{:ok, collections} = Qdrant.list_collections()

# Get collection info
{:ok, info} = Qdrant.collection_info(collection_name)

# Check if collection exists
{:ok, %{"result" => %{"exists" => true}}} = Qdrant.collection_exists(collection_name)

# Update collection parameters
{:ok, _} = Qdrant.update_collection(collection_name, %{
  optimizers_config: %{
    deleted_threshold: 0.2
  }
})

# Delete a collection
{:ok, _} = Qdrant.delete_collection(collection_name)
```

### Points

```elixir
collection_name = "my-collection"

# Create embeddings for some text
vector1 = [0.1, 0.2, 0.3] # Your embedding vector
vector2 = [0.4, 0.5, 0.6]

# Insert vectors with batch
{:ok, _} = Qdrant.upsert_point(collection_name, %{
  batch: %{
    ids: [1, 2],
    vectors: [vector1, vector2]
  }
})

# Or insert points one by one
{:ok, _} = Qdrant.upsert_point(collection_name, %{
  points: [
    %{id: 1, vector: vector1, payload: %{text: "Hello"}},
    %{id: 2, vector: vector2, payload: %{text: "World"}}
  ]
})

# Search for similar vectors
query_vector = [0.15, 0.25, 0.35]
{:ok, results} = Qdrant.search_points(collection_name, %{
  vector: query_vector,
  limit: 3,
  with_payload: true
})

# Get specific points by ID
{:ok, points} = Qdrant.get_points(collection_name, %{
  ids: [1, 2],
  with_payload: true,
  with_vector: true
})

# Get a single point
{:ok, point} = Qdrant.get_point(collection_name, 1)

# Delete points
{:ok, _} = Qdrant.delete_points(collection_name, %{
  points: [1, 2]
})
```

### Advanced Features

The library supports many advanced features including:

- **Aliases**: Manage collection aliases
- **Indexes**: Create and manage field indexes for faster filtering
- **Snapshots**: Backup and restore collections
- **Cluster operations**: Manage distributed setups
- **Service endpoints**: Health checks, telemetry, metrics

For full API documentation, see the [module documentation](https://hexdocs.pm/qdrant).

## Direct HTTP Module Access

You can also access the HTTP modules directly for more control:

```elixir
# Collections
alias Qdrant.Api.Http.Collections
{:ok, collections} = Collections.list_collections()

# Points
alias Qdrant.Api.Http.Points
{:ok, results} = Points.search_points("my-collection", %{vector: [0.1, 0.2], limit: 5})

# Service
alias Qdrant.Api.Http.Service
{:ok, info} = Service.root() # Get server version info
{:ok, health} = Service.healthz() # Health check
```

## Architecture

The client uses the modern Tesla HTTP client pattern with middleware for:
- Base URL configuration
- API key authentication
- JSON encoding/decoding

All modules follow consistent patterns and provide full coverage of the Qdrant REST API.

## Contributing

- Fork the repository
- Create a branch for your changes
- Make your changes
- Run `mix format` to format your code
- Run `mix compile` to ensure everything compiles
- Submit a pull request

## Change Log

Generate change log with `git-chglog -o CHANGELOG.md`

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details
