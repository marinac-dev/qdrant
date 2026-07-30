defmodule Qdrant.Config do
  @moduledoc """
  Resolves compatibility application and environment configuration for Qdrant.

  Application configuration takes precedence over environment variables. New code
  should pass options directly to `Qdrant.Client.new/1`.

  ## Configuration

  Configure a full URL with `:url`:

      config :qdrant,
        url: "http://localhost:6333",
        api_key: "your-api-key",
        require_api_key: false

  The compatibility `:database_url` and `:port` options are also supported:

      config :qdrant,
        database_url: "http://localhost",
        port: 6333,
        api_key: "your-api-key"

  The equivalent environment variables are `QDRANT_URL`, `QDRANT_DATABASE_URL`,
  `QDRANT_PORT`, `QDRANT_API_KEY`, `QDRANT_REQUIRE_API_KEY`, and
  `QDRANT_ALLOW_INSECURE_API_KEY`.

  Full URLs take precedence over database URL and port settings. When no URL is
  configured, the default is `"http://localhost:6333"`.

  `require_api_key` defaults to `true` for hosts equal to `cloud.qdrant.io` or
  ending in `.cloud.qdrant.io`, and `false` otherwise. Environment booleans must
  be `"true"` or `"false"`, and ports must be integers from 1 through 65535.
  """

  alias Qdrant.{Client, Error}

  @default_url "http://localhost:6333"
  @default_port 6333

  @doc """
  Returns the options resolved from compatibility application configuration and
  environment variables.

  The returned options can be passed to `Qdrant.Client.new/1`. Invalid URL,
  port, boolean, interface, or other configuration values are returned as
  `{:error, %Qdrant.Error{kind: :configuration}}`.

  Optional application settings for `:interface`, `:adapter`, `:adapter_opts`, `:base_path`,
  and `:max_response_bytes` are included when configured.
  """
  @spec client_options() :: {:ok, keyword()} | {:error, Error.t()}
  def client_options do
    with {:ok, interface} <- Client.validate_interface(Application.get_env(:qdrant, :interface, :rest)),
         {:ok, url} <- configured_url(),
         {:ok, require_api_key} <- configured_boolean(:require_api_key, "QDRANT_REQUIRE_API_KEY"),
         {:ok, allow_insecure_api_key} <-
           configured_boolean(:allow_insecure_api_key, "QDRANT_ALLOW_INSECURE_API_KEY") do
      opts = [
        interface: interface,
        url: url,
        api_key: app_or_env(:api_key, "QDRANT_API_KEY"),
        allow_insecure_api_key: allow_insecure_api_key || false
      ]

      opts = if is_nil(require_api_key), do: opts, else: Keyword.put(opts, :require_api_key, require_api_key)
      {:ok, put_optional_application_options(opts)}
    end
  end

  @doc """
  Returns the validated base URL for compatibility requests.

  Configuration is checked in this order: application `:url`, application
  `:database_url` and `:port`, `QDRANT_URL`, `QDRANT_DATABASE_URL` and
  `QDRANT_PORT`, `QDRANT_PORT` with localhost, and the default URL.

  Raises `Qdrant.Error` when the configured URL or port is invalid.
  """
  @spec base_url() :: String.t()
  def base_url do
    case configured_url() do
      {:ok, url} -> url
      {:error, error} -> raise error
    end
  end

  @doc """
  Returns the configured full Qdrant URL, without applying fallback settings.

  Returns `nil` when neither application `:url` nor `QDRANT_URL` is set.
  """
  @spec get_url() :: String.t() | nil
  def get_url, do: Application.get_env(:qdrant, :url) || System.get_env("QDRANT_URL")

  @doc """
  Returns the configured database URL without a port.

  Checks application `:database_url`, then `QDRANT_DATABASE_URL`, and defaults
  to `"http://localhost"`.
  """
  @spec get_database_url() :: String.t()
  def get_database_url,
    do: Application.get_env(:qdrant, :database_url) || System.get_env("QDRANT_DATABASE_URL") || "http://localhost"

  @doc """
  Returns the configured Qdrant port.

  Checks application `:port`, then `QDRANT_PORT`, and defaults to `6333`. The
  value must be an integer from 1 through 65535; invalid values raise
  `Qdrant.Error`.
  """
  @spec get_port() :: pos_integer()
  def get_port do
    value = Application.get_env(:qdrant, :port) || System.get_env("QDRANT_PORT") || @default_port

    case parse_port(value) do
      {:ok, port} -> port
      {:error, error} -> raise error
    end
  end

  @doc """
  Returns whether API key authentication is required.

  An explicit application `:require_api_key` or `QDRANT_REQUIRE_API_KEY` value
  takes precedence. When no value is configured, authentication is required for
  Qdrant Cloud hosts and optional for other hosts.

  Raises `Qdrant.Error` when the configured boolean or URL is invalid.
  """
  @spec require_api_key?() :: boolean()
  def require_api_key? do
    with {:ok, value} <- configured_boolean(:require_api_key, "QDRANT_REQUIRE_API_KEY"),
         {:ok, url} <- configured_url() do
      if is_nil(value), do: cloud_url?(url), else: value
    else
      {:error, error} -> raise error
    end
  end

  @doc """
  Returns the API key from application configuration or `QDRANT_API_KEY`.

  Application `:api_key` takes precedence. Returns `nil` when no API key is
  configured.
  """
  @spec get_api_key() :: String.t() | nil
  def get_api_key, do: app_or_env(:api_key, "QDRANT_API_KEY")

  @doc """
  Returns the Tesla adapter used for compatibility requests.

  An `:adapter` option takes precedence, followed by application `:adapter`,
  application `:tesla_adapter`, and `Tesla.Adapter.Finch`.
  """
  @spec get_adapter(keyword()) :: module() | function()
  def get_adapter(opts \\ []) do
    Keyword.get(opts, :adapter) || Application.get_env(:qdrant, :adapter) ||
      Application.get_env(:qdrant, :tesla_adapter) || Tesla.Adapter.Finch
  end

  defp configured_url do
    cond do
      value = Application.get_env(:qdrant, :url) ->
        validate_url_source(value)

      value = Application.get_env(:qdrant, :database_url) ->
        combine_url_and_port(value, Application.get_env(:qdrant, :port, @default_port))

      value = System.get_env("QDRANT_URL") ->
        validate_url_source(value)

      value = System.get_env("QDRANT_DATABASE_URL") ->
        combine_url_and_port(value, System.get_env("QDRANT_PORT") || @default_port)

      value = System.get_env("QDRANT_PORT") ->
        combine_url_and_port("http://localhost", value)

      true ->
        {:ok, @default_url}
    end
  end

  defp validate_url_source(value) when is_binary(value) do
    case Qdrant.Client.validate_url(value) do
      {:ok, url, _uri} -> {:ok, url}
      {:error, error} -> {:error, error}
    end
  end

  defp validate_url_source(_), do: configuration_error("URL must be a string")

  defp combine_url_and_port(base, port_value) when is_binary(base) do
    with {:ok, port} <- parse_port(port_value),
         {:ok, normalized, uri} <- Qdrant.Client.validate_url(base),
         :ok <- reject_existing_port(base, uri) do
      uri = URI.parse(normalized)
      {:ok, URI.to_string(%{uri | port: port})}
    end
  end

  defp combine_url_and_port(_, _), do: configuration_error("database URL must be a string")

  defp reject_existing_port(source, %URI{port: port, scheme: scheme}) do
    default_port = if scheme == "https", do: 443, else: 80

    if explicit_port?(source) or port != default_port do
      configuration_error("database URL must not contain a port when :port or QDRANT_PORT is used")
    else
      :ok
    end
  end

  defp explicit_port?(source) do
    authority = source |> String.split("//", parts: 2) |> List.last() |> String.split("/", parts: 2) |> hd()
    Regex.match?(~r/:\d+$/, authority) or Regex.match?(~r/\]:\d+$/, authority)
  end

  defp parse_port(value) when is_integer(value) and value in 1..65_535, do: {:ok, value}

  defp parse_port(value) when is_binary(value) do
    case Integer.parse(value) do
      {port, ""} when port in 1..65_535 -> {:ok, port}
      _ -> configuration_error("port must be an integer between 1 and 65535")
    end
  end

  defp parse_port(_), do: configuration_error("port must be an integer between 1 and 65535")

  defp configured_boolean(app_key, env_key) do
    case Application.fetch_env(:qdrant, app_key) do
      {:ok, value} when is_boolean(value) -> {:ok, value}
      {:ok, _value} -> configuration_error("#{app_key} must be a boolean")
      :error -> parse_environment_boolean(env_key, System.get_env(env_key))
    end
  end

  defp parse_environment_boolean(_name, nil), do: {:ok, nil}
  defp parse_environment_boolean(_name, value) when value in ["true", "TRUE"], do: {:ok, true}
  defp parse_environment_boolean(_name, value) when value in ["false", "FALSE"], do: {:ok, false}
  defp parse_environment_boolean(name, _value), do: configuration_error("#{name} must be true or false")

  defp put_optional_application_options(opts) do
    [:adapter, :adapter_opts, :base_path, :max_response_bytes]
    |> Enum.reduce(opts, fn key, acc ->
      case Application.fetch_env(:qdrant, key) do
        {:ok, value} -> Keyword.put(acc, key, value)
        :error -> acc
      end
    end)
  end

  defp app_or_env(app_key, env_key), do: Application.get_env(:qdrant, app_key) || System.get_env(env_key)

  defp cloud_url?(url) do
    host = URI.parse(url).host |> String.downcase()
    host == "cloud.qdrant.io" or String.ends_with?(host, ".cloud.qdrant.io")
  end

  defp configuration_error(reason), do: {:error, %Error{kind: :configuration, reason: reason}}
end
