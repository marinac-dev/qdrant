defmodule Qdrant.Config do
  @moduledoc """
  Configuration module for Qdrant client.

  This module handles all configuration logic, checking application config first,
  then environment variables, and finally defaults. Application config takes priority.

  ## Configuration Options

  You can configure the client in your `config/config.exs`:

  ```elixir
  config :qdrant,
    url: "http://localhost:6333",
    api_key: "your-api-key"
  ```

  Or use separate URL and port (for backward compatibility):

  ```elixir
  config :qdrant,
    database_url: "http://localhost",
    port: 6333,
    api_key: "your-api-key"
  ```

  ## Environment Variables

  Alternatively, you can set these via environment variables:
  - `QDRANT_URL` - Full Qdrant server URL (e.g., `http://localhost:6333`)
  - `QDRANT_DATABASE_URL` - Qdrant server URL without port (default: `http://localhost`)
  - `QDRANT_PORT` - Qdrant server port (default: `6333`)
  - `QDRANT_API_KEY` - API key for authentication (optional)

  Note: If both `QDRANT_URL` and `QDRANT_DATABASE_URL`+`QDRANT_PORT` are set,
  `QDRANT_URL` takes priority.
  """

  require Logger

  @default_url "http://localhost"
  @default_port 6333

  @doc """
  Returns the base URL for Qdrant API requests.

  This function checks for configuration in the following order:
  1. Application config (`:url` - full URL)
  2. Application config (`:database_url` + `:port`)
  3. Environment variable `QDRANT_URL`
  4. Environment variables `QDRANT_DATABASE_URL` + `QDRANT_PORT`
  5. Default values

  Returns a string like `"http://localhost:6333"`.
  """
  def base_url do
    case get_url() do
      nil ->
        # Fallback to separate URL and port
        "#{get_database_url()}:#{get_port()}"

      url ->
        url
    end
  end

  @doc """
  Returns the full URL from configuration or environment variables.

  Returns `nil` if not set, allowing fallback to separate URL and port.
  """
  def get_url do
    case Application.get_env(:qdrant, :url) do
      nil ->
        case System.get_env("QDRANT_URL") do
          nil -> nil
          env_url -> env_url
        end

      config_url ->
        config_url
    end
  end

  @doc """
  Returns the database URL from configuration or environment variables.

  This is used as a fallback when `:url` is not set.
  Returns the default URL if not configured.
  """
  def get_database_url do
    case Application.get_env(:qdrant, :database_url) do
      nil ->
        case System.get_env("QDRANT_DATABASE_URL") do
          nil ->
            Logger.warning("Qdrant database URL not set in config or environment variables. Using default URL.")
            @default_url

          env_url ->
            env_url
        end

      config_url ->
        config_url
    end
  end

  @doc """
  Returns the port from configuration or environment variables.

  Returns the default port if not configured.
  """
  def get_port do
    case Application.get_env(:qdrant, :port) do
      nil ->
        case System.get_env("QDRANT_PORT") do
          nil ->
            Logger.warning("Qdrant port not set in config or environment variables. Using default port #{@default_port}.")
            @default_port

          env_port ->
            case Integer.parse(env_port) do
              {port, _} ->
                port

              :error ->
                Logger.warning("Invalid QDRANT_PORT environment variable: #{env_port}")
                raise "Invalid QDRANT_PORT environment variable"
            end
        end

      config_port ->
        config_port
    end
  end

  @doc """
  Returns the API key from configuration or environment variables.

  Returns `nil` if not set (authentication is optional).
  """
  def get_api_key do
    case Application.get_env(:qdrant, :api_key) do
      nil ->
        case System.get_env("QDRANT_API_KEY") do
          nil ->
            Logger.warning("Qdrant API key not set in config or environment variables. Requests will be made without an API key.")
            nil

          env_key ->
            env_key
        end

      config_key ->
        config_key
    end
  end
end
