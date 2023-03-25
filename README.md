# Qdrant

An Elixir client for the Qdrant vector similarity search engine. This library allows you to interact with the Qdrant API, providing functionality to create collections, insert vectors, search, and delete data.

## Installation

It's [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `qdrant` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:qdrant, "~> 0.1.0"}
  ]
end
```

## Config

```elixir
config :qdrant, 
  qdrant_url: System.get_env("QDRANT_URL") || "http://localhost:6333"
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/qdrant>.

github_changelog_generator -u marinac-dev -p qdrant
