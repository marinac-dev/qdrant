defmodule Qdrant.Client do
  @moduledoc """
  Immutable configuration for one Qdrant client.

  Construct independent clients with `new/1`; each value retains its own URL,
  credentials, adapter, and timeout configuration.

      iex> {:ok, client} = Qdrant.Client.new(url: "http://localhost:6333")
      iex> client.url
      "http://localhost:6333"

      iex> {:error, %Qdrant.Error{kind: :configuration}} = Qdrant.Client.new(url: "not-a-url")
  """

  alias Qdrant.Error

  @default_adapter_opts [name: Qdrant.Finch, receive_timeout: 30_000, pool_timeout: 5_000]
  @default_max_response_bytes 50 * 1024 * 1024

  @enforce_keys [:interface, :url, :adapter, :adapter_opts, :max_response_bytes, :tesla]
  defstruct [:interface, :url, :api_key, :adapter, :tesla, adapter_opts: [], base_path: "", max_response_bytes: nil]

  @type t :: %__MODULE__{
          interface: :rest,
          url: String.t(),
          api_key: String.t() | nil,
          adapter: module() | function(),
          adapter_opts: keyword(),
          base_path: String.t(),
          max_response_bytes: pos_integer(),
          tesla: Tesla.Client.t()
        }

  @spec new(keyword()) :: {:ok, t()} | {:error, Error.t()}
  def new(opts \\ [])

  def new(opts) when is_list(opts) do
    with {:ok, interface} <- validate_interface(Keyword.get(opts, :interface, :rest)),
         {:ok, url, uri} <- validate_url(Keyword.get(opts, :url, "http://localhost:6333")),
         {:ok, api_key} <- validate_api_key(Keyword.get(opts, :api_key)),
         {:ok, require_api_key} <- require_api_key(opts, uri),
         :ok <- validate_required_key(require_api_key, api_key),
         :ok <- validate_key_transport(uri, api_key, Keyword.get(opts, :allow_insecure_api_key, false)),
         {:ok, base_path} <- normalize_base_path(Keyword.get(opts, :base_path, "")),
         {:ok, max_response_bytes} <-
           validate_max_response_bytes(Keyword.get(opts, :max_response_bytes, @default_max_response_bytes)),
         {:ok, adapter_opts} <- adapter_options(opts) do
      adapter = Keyword.get(opts, :adapter, Tesla.Adapter.Finch)
      middleware = middleware(url <> base_path, api_key)
      tesla = Tesla.client(middleware, adapter_spec(adapter, adapter_opts))

      {:ok,
       %__MODULE__{
         interface: interface,
         url: url,
         api_key: api_key,
         adapter: adapter,
         adapter_opts: adapter_opts,
         base_path: base_path,
         max_response_bytes: max_response_bytes,
         tesla: tesla
       }}
    end
  end

  def new(_), do: configuration_error("client options must be a keyword list")

  @spec new!(keyword()) :: t()
  def new!(opts \\ []) do
    case new(opts) do
      {:ok, client} -> client
      {:error, error} -> raise error
    end
  end

  @doc false
  def passthrough_json(data), do: {:ok, data}

  @doc false
  @spec execute(t(), keyword()) :: {:ok, Tesla.Env.t()} | {:error, term()}
  def execute(%__MODULE__{interface: :rest, tesla: tesla}, opts), do: Tesla.request(tesla, opts)

  @doc false
  @spec validate_interface(term()) :: {:ok, :rest} | {:error, Error.t()}
  def validate_interface(value) when value in [:rest, "rest"], do: {:ok, :rest}

  def validate_interface(value) when value in [:grpc, "grpc"],
    do: configuration_error("gRPC is unsupported; use the REST interface")

  def validate_interface(value),
    do: configuration_error("unsupported interface #{inspect(value)}; use REST")

  @doc false
  @spec validate_url(term()) :: {:ok, String.t(), URI.t()} | {:error, Error.t()}
  def validate_url(value) when is_binary(value) do
    uri = URI.parse(value)

    cond do
      uri.scheme not in ["http", "https"] ->
        configuration_error("URL scheme must be http or https")

      is_nil(uri.host) or uri.host == "" ->
        configuration_error("URL must include a host")

      not is_nil(uri.userinfo) ->
        configuration_error("URL credentials are unsupported; use :api_key")

      not is_nil(uri.query) or not is_nil(uri.fragment) ->
        configuration_error("URL must not include a query or fragment")

      malformed_authority?(value, uri) ->
        configuration_error("URL contains a malformed or duplicated port")

      effective_port(uri) not in 1..65_535 ->
        configuration_error("URL port must be between 1 and 65535")

      true ->
        path = normalize_url_path(uri.path)
        normalized = URI.to_string(%{uri | path: path})
        {:ok, normalized, %{uri | path: path, port: effective_port(uri)}}
    end
  end

  def validate_url(_), do: configuration_error("URL must be a string")

  defp middleware(base_url, api_key) do
    headers = if api_key, do: [{"api-key", api_key}], else: []

    [
      {Tesla.Middleware.BaseUrl, base_url},
      {Tesla.Middleware.Headers, headers},
      {Tesla.Middleware.JSON, engine: JSON, decode: &__MODULE__.passthrough_json/1}
    ]
  end

  defp adapter_spec(adapter, []), do: adapter
  defp adapter_spec(adapter, _opts) when is_function(adapter), do: adapter
  defp adapter_spec(adapter, opts), do: {adapter, opts}

  defp adapter_options(opts) do
    value =
      if Keyword.has_key?(opts, :adapter_opts) do
        Keyword.get(opts, :adapter_opts)
      else
        @default_adapter_opts
      end

    if Keyword.keyword?(value), do: {:ok, value}, else: configuration_error(":adapter_opts must be a keyword list")
  end

  defp validate_api_key(nil), do: {:ok, nil}
  defp validate_api_key(value) when is_binary(value) and value != "", do: {:ok, value}
  defp validate_api_key(_), do: configuration_error(":api_key must be a non-empty string or nil")

  defp require_api_key(opts, uri) do
    case Keyword.fetch(opts, :require_api_key) do
      {:ok, value} when is_boolean(value) -> {:ok, value}
      {:ok, _} -> configuration_error(":require_api_key must be a boolean")
      :error -> {:ok, cloud_host?(uri.host)}
    end
  end

  defp validate_required_key(true, nil), do: configuration_error("an API key is required for this Qdrant URL")
  defp validate_required_key(_, _), do: :ok

  defp validate_key_transport(%URI{scheme: "http", host: host}, api_key, allow?) when not is_nil(api_key) do
    cond do
      allow? == true -> :ok
      allow? != false -> configuration_error(":allow_insecure_api_key must be a boolean")
      loopback_host?(host) -> :ok
      true -> configuration_error("refusing to send an API key over plain HTTP to a non-loopback host")
    end
  end

  defp validate_key_transport(_uri, _api_key, allow?) when is_boolean(allow?), do: :ok

  defp validate_key_transport(_uri, _api_key, _allow?),
    do: configuration_error(":allow_insecure_api_key must be a boolean")

  defp normalize_base_path(""), do: {:ok, ""}

  defp normalize_base_path(value) when is_binary(value) do
    if String.contains?(value, ["?", "#"]) do
      configuration_error(":base_path must not include a query or fragment")
    else
      {:ok, "/" <> (value |> String.trim("/") |> String.trim_trailing("/"))}
    end
  end

  defp normalize_base_path(_), do: configuration_error(":base_path must be a string")

  defp validate_max_response_bytes(value) when is_integer(value) and value > 0, do: {:ok, value}
  defp validate_max_response_bytes(_), do: configuration_error(":max_response_bytes must be a positive integer")

  defp malformed_authority?(source, uri) do
    authority = source |> String.split("//", parts: 2) |> List.last() |> String.split("/", parts: 2) |> hd()

    (String.contains?(authority, "::") and not String.starts_with?(authority, "[")) or
      Regex.match?(~r/\]:\d+:/, authority) or
      (not String.starts_with?(authority, "[") and length(String.split(authority, ":")) > 2) or
      (is_nil(uri.port) and Regex.match?(~r/:/, authority))
  end

  defp effective_port(%URI{port: port}) when is_integer(port), do: port
  defp effective_port(%URI{scheme: "https"}), do: 443
  defp effective_port(_), do: 80

  defp normalize_url_path(path) when path in [nil, "/"], do: nil
  defp normalize_url_path(path), do: String.trim_trailing(path, "/")

  defp cloud_host?(host) do
    host = String.downcase(host)
    host == "cloud.qdrant.io" or String.ends_with?(host, ".cloud.qdrant.io")
  end

  defp loopback_host?(host) do
    host = String.downcase(host)
    host == "localhost" or host == "::1" or String.starts_with?(host, "127.")
  end

  defp configuration_error(reason), do: {:error, %Error{kind: :configuration, reason: reason}}
end

defimpl Inspect, for: Qdrant.Client do
  import Inspect.Algebra

  def inspect(client, opts) do
    fields = [
      interface: client.interface,
      url: client.url,
      api_key: if(client.api_key, do: "[REDACTED]", else: nil),
      adapter: client.adapter,
      adapter_opts: client.adapter_opts,
      base_path: client.base_path,
      max_response_bytes: client.max_response_bytes
    ]

    concat(["#Qdrant.Client<", to_doc(fields, opts), ">"])
  end
end
