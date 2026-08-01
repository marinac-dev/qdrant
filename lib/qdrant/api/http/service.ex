defmodule Qdrant.Api.Http.Service do
  @moduledoc """
  Qdrant service endpoints for health checks, telemetry, metrics, and system information.

  Functions accepting a `Qdrant.Client` are the primary API. No-client forms
  remain available for compatibility with application and environment configuration.
  """

  alias Qdrant.Api.Http.Request
  alias Qdrant.{Client, Config, Types}

  @doc """
  Returns information about the running Qdrant instance, including its version and commit id.

  ## Example

      client = Qdrant.Client.new!(url: "http://localhost:6333")
      Qdrant.Api.Http.Service.root(client)
  """
  @spec root(Client.t()) :: Types.result()
  @spec root() :: Types.result()
  def root, do: with_compat_client(&root/1)
  def root(%Client{} = client), do: Request.request(client, :get, "/")

  @doc """
  Collect telemetry data including application, system, collection, cluster, configuration,
  and statistics information.

  Options:

  * `:anonymize` - anonymize the result
  * `:details_level` - level of detail, with a minimum of zero

  ## Example

      client = Qdrant.Client.new!(url: "http://localhost:6333")
      Qdrant.Api.Http.Service.telemetry(client, anonymize: true, details_level: 1)
  """
  @spec telemetry(Client.t()) :: Types.result()
  @spec telemetry(Client.t(), Types.request_options()) :: Types.result()
  @spec telemetry() :: Types.result()
  @spec telemetry(boolean() | nil) :: Types.result()
  @spec telemetry(boolean() | nil, integer() | nil) :: Types.result()
  def telemetry, do: with_compat_client(&telemetry/1)
  def telemetry(%Client{} = client), do: telemetry(client, [])

  def telemetry(anonymize),
    do: with_compat_client(&telemetry(&1, anonymize: anonymize))

  def telemetry(%Client{} = client, opts) do
    query = [anonymize: Keyword.get(opts, :anonymize), details_level: Keyword.get(opts, :details_level)]
    Request.request(client, :get, "/telemetry", query: query)
  end

  def telemetry(anonymize, details_level),
    do: with_compat_client(&telemetry(&1, anonymize: anonymize, details_level: details_level))

  @doc """
  Collect Prometheus metrics data as text.

  Options:

  * `:anonymize` - anonymize the result

  ## Example

      client = Qdrant.Client.new!(url: "http://localhost:6333")
      Qdrant.Api.Http.Service.metrics(client, anonymize: false)
  """
  @spec metrics(Client.t()) :: Types.result(String.t())
  @spec metrics(Client.t(), Types.request_options()) :: Types.result(String.t())
  @spec metrics() :: Types.result(String.t())
  @spec metrics(boolean() | nil) :: Types.result(String.t())
  def metrics, do: with_compat_client(&metrics/1)
  def metrics(%Client{} = client), do: metrics(client, [])

  def metrics(anonymize),
    do: with_compat_client(&metrics(&1, anonymize: anonymize))

  def metrics(%Client{} = client, opts) do
    Request.request(client, :get, "/metrics",
      query: [anonymize: Keyword.get(opts, :anonymize)],
      response: :text
    )
  end

  @doc """
  Get lock options.

  If writing is locked, all write operations and collection creation are forbidden.

  ## Example

      client = Qdrant.Client.new!(url: "http://localhost:6333")
      Qdrant.Api.Http.Service.lock_options(client)
  """
  @spec lock_options(Client.t()) :: Types.result()
  @spec lock_options() :: Types.result()
  def lock_options, do: with_compat_client(&lock_options/1)
  def lock_options(%Client{} = client), do: Request.request(client, :get, "/locks")

  @doc """
  Set lock options and return the previous lock options.

  ## Example

      client = Qdrant.Client.new!(url: "http://localhost:6333")
      body = %{error_message: "Maintenance mode", write: true}
      Qdrant.Api.Http.Service.set_lock_options(client, body)
  """
  @spec set_lock_options(Client.t(), Types.request_body()) :: Types.result()
  @spec set_lock_options(Types.request_body()) :: Types.result()
  def set_lock_options(body), do: with_compat_client(&set_lock_options(&1, body))

  def set_lock_options(%Client{} = client, body),
    do: Request.request(client, :post, "/locks", body: body)

  @doc """
  Health check endpoint.

  The response body may be text, empty, or JSON and is returned without coercion.

  ## Example

      client = Qdrant.Client.new!(url: "http://localhost:6333")
      Qdrant.Api.Http.Service.healthz(client)
  """
  @spec healthz(Client.t()) :: Types.result(Types.health_body())
  @spec healthz() :: Types.result(Types.health_body())
  def healthz, do: with_compat_client(&healthz/1)
  def healthz(%Client{} = client), do: Request.request(client, :get, "/healthz")

  @doc """
  Kubernetes liveness endpoint.

  The response body may be text, empty, or JSON and is returned without coercion.

  ## Example

      client = Qdrant.Client.new!(url: "http://localhost:6333")
      Qdrant.Api.Http.Service.livez(client)
  """
  @spec livez(Client.t()) :: Types.result(Types.health_body())
  @spec livez() :: Types.result(Types.health_body())
  def livez, do: with_compat_client(&livez/1)
  def livez(%Client{} = client), do: Request.request(client, :get, "/livez")

  @doc """
  Kubernetes readiness endpoint.

  The response body may be text, empty, or JSON and is returned without coercion.

  ## Example

      client = Qdrant.Client.new!(url: "http://localhost:6333")
      Qdrant.Api.Http.Service.readyz(client)
  """
  @spec readyz(Client.t()) :: Types.result(Types.health_body())
  @spec readyz() :: Types.result(Types.health_body())
  def readyz, do: with_compat_client(&readyz/1)
  def readyz(%Client{} = client), do: Request.request(client, :get, "/readyz")

  @doc """
  Get a report of performance issues and configuration suggestions.

  **Beta:** This endpoint is unstable and may change between Qdrant releases.

  ## Example

      client = Qdrant.Client.new!(url: "http://localhost:6333")
      Qdrant.Api.Http.Service.get_issues(client)
  """
  @spec get_issues(Client.t()) :: Types.result()
  @spec get_issues() :: Types.result()
  def get_issues, do: with_compat_client(&get_issues/1)
  def get_issues(%Client{} = client), do: Request.request(client, :get, "/issues")

  @doc """
  Remove all issues reported so far.

  **Beta:** This endpoint is unstable and may change between Qdrant releases.

  ## Example

      client = Qdrant.Client.new!(url: "http://localhost:6333")
      Qdrant.Api.Http.Service.clear_issues(client)
  """
  @spec clear_issues(Client.t()) :: Types.result()
  @spec clear_issues() :: Types.result()
  def clear_issues, do: with_compat_client(&clear_issues/1)
  def clear_issues(%Client{} = client), do: Request.request(client, :delete, "/issues")

  defp with_compat_client(callback) do
    with {:ok, opts} <- Config.client_options(),
         {:ok, client} <- Client.new(default_insecure_api_key_option(opts)) do
      callback.(client)
    end
  end

  defp default_insecure_api_key_option(opts) do
    if is_nil(opts[:allow_insecure_api_key]),
      do: Keyword.put(opts, :allow_insecure_api_key, false),
      else: opts
  end
end
