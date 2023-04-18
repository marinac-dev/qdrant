# Qdrant Elixir Client

An Elixir client for the Qdrant vector similarity search engine. This library provides a convenient way to interact with the Qdrant API, offering functionality to create collections, insert vectors, search, delete data, and more.

## Installation

It's [available in Hex](https://hexdocs.pm/qdrant/readme.html), the package can be installed
by adding `qdrant` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:qdrant, "~> 0.5.0"}
    # Or use the latest version from GitHub | Recommended during development phase
    {:qdrant, git: "git@github.com:marinac-dev/qdrant.git"},
  ]
end
```

## Config

```elixir
config :qdrant,
  interface: "rest", # gRPC not yet supported
  database_url: System.get_env("QDRANT_DATABASE_URL")
```

## Usage

The Qdrant Elixir Client provides a simple interface for interacting with the Qdrant API. For example, you can create a new collection, insert vectors, search, and delete data using the provided functions.

```elixir
collection_name = "my-collection"

# Create a new collection
# The vectors are 1536-dimensional (because of OpenAi embedding) and use the Cosine distance metric
Qdrant.create_collection(collection_name, %{vectors: %{size: 1536, distance: "Cosine"}})

# Create embeddings for some text
vector1 = OpenAi.embed_text("Hello world")
vector2 = OpenAi.embed_text("This is OpenAI")

# Now we can insert the vectors with batch
Qdrant.upsert_points(collection_name, %{batch: %{ids: [1,2], vectors: [vector1, vector2]}})
# Or one by one
Qdrant.upsert_point(collection_name, %{points: [%{id: 1, vector: vector1}, %{id: 2, vector: vector2}]})
```
