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
    {:qdrant, git: "git@github.com:marinac-dev/qdrant.git"},
  ]
end
```

## Config

```elixir
config :qdrant,
  port: 6333,
  interface: "rest", # gRPC not yet supported
  database_url: System.get_env("QDRANT_DATABASE_URL"),
  # If you are using cloud version of Qdrant, add API key
  api_key: System.get_env("QDRANT_API_KEY")
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

# Search for similar vectors
vector3 = OpenAi.embed_text("Hello world!")
Qdrant.search_points(collection_name, %{vector: vector3, limit: 3})
```

## Contributing

- Fork the repository
- Create a branch for your changes
- Make your changes
- Run `mix format` to format your code

## Change Log

Generate change log with `git-chglog -o CHANGELOG.md`

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details
