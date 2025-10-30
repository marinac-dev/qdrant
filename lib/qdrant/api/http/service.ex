defmodule Qdrant.Api.Http.Service do
  @moduledoc """
  Qdrant service endpoints for health checks, telemetry, metrics, and system information.
  """

  alias Qdrant.Api.Http.Client

  defp client, do: Client.client()

  @doc """
  Returns information about the running Qdrant instance like version and commit id.

  ## Example

      iex> Qdrant.Api.Http.Service.root()
      {:ok, %{"version" => "1.0.0", "commit" => "abc123"}}

  """
  @spec root() :: {:ok, map()} | {:error, any()}
  def root do
    client()
    |> Tesla.get("/")
    |> parse_response()
  end

  @doc """
  Collect telemetry data including app info, system info, collections info, cluster info, configs and statistics.

  ## Parameters

  * `anonymize` - Optional boolean to anonymize result
  * `details_level` - Optional integer level of details (minimum 0)

  ## Example

      iex> Qdrant.Api.Http.Service.telemetry()
      {:ok, %{"result" => %{...}, "status" => "ok"}}

  """
  @spec telemetry(boolean() | nil, integer() | nil) :: {:ok, map()} | {:error, any()}
  def telemetry(anonymize \\ nil, details_level \\ nil) do
    path =
      "/telemetry"
      |> Client.add_query_param("anonymize", anonymize)
      |> Client.add_query_param("details_level", details_level)

    client()
    |> Tesla.get(path)
    |> parse_response()
  end

  @doc """
  Collect Prometheus metrics data.

  Returns metrics data in Prometheus format including app info, collections info, cluster info and statistics.

  ## Parameters

  * `anonymize` - Optional boolean to anonymize result

  ## Example

      iex> Qdrant.Api.Http.Service.metrics()
      {:ok, "# HELP app_info..."}

  """
  @spec metrics(boolean() | nil) :: {:ok, String.t()} | {:error, any()}
  def metrics(anonymize \\ nil) do
    path = "/metrics" |> Client.add_query_param("anonymize", anonymize)

    client()
    |> Tesla.get(path)
    |> parse_response_text()
  end

  @doc """
  Get lock options.

  If write is locked, all write operations and collection creation are forbidden.

  ## Example

      iex> Qdrant.Api.Http.Service.lock_options()
      {:ok, %{"result" => %{"write" => false}}}

  """
  @spec lock_options() :: {:ok, map()} | {:error, any()}
  def lock_options do
    client()
    |> Tesla.get("/locks")
    |> parse_response()
  end

  @doc """
  Set lock options.

  If write is locked, all write operations and collection creation are forbidden.
  Returns previous lock options.

  ## Parameters

  * `body` - Lock configuration with `error_message` and `write` flag

  ## Example

      iex> body = %{error_message: "Maintenance mode", write: true}
      iex> Qdrant.Api.Http.Service.set_lock_options(body)
      {:ok, %{"result" => %{"error_message" => "Maintenance mode", "write" => true}}}

  """
  @spec set_lock_options(map()) :: {:ok, map()} | {:error, any()}
  def set_lock_options(body) do
    client()
    |> Tesla.post("/locks", body)
    |> parse_response()
  end

  @doc """
  Health check endpoint.

  Returns a simple health check response.

  ## Example

      iex> Qdrant.Api.Http.Service.healthz()
      {:ok, "healthz check passed"}

  """
  @spec healthz() :: {:ok, String.t()} | {:error, any()}
  def healthz do
    client()
    |> Tesla.get("/healthz")
    |> parse_response_text()
  end

  @doc """
  Kubernetes livez endpoint.

  An endpoint for health checking used in Kubernetes.

  ## Example

      iex> Qdrant.Api.Http.Service.livez()
      {:ok, "healthz check passed"}

  """
  @spec livez() :: {:ok, String.t()} | {:error, any()}
  def livez do
    client()
    |> Tesla.get("/livez")
    |> parse_response_text()
  end

  @doc """
  Kubernetes readyz endpoint.

  An endpoint for health checking used in Kubernetes.

  ## Example

      iex> Qdrant.Api.Http.Service.readyz()
      {:ok, "healthz check passed"}

  """
  @spec readyz() :: {:ok, String.t()} | {:error, any()}
  def readyz do
    client()
    |> Tesla.get("/readyz")
    |> parse_response_text()
  end

  @doc """
  Get a report of performance issues and configuration suggestions.

  This is a Beta endpoint.

  ## Example

      iex> Qdrant.Api.Http.Service.get_issues()
      {:ok, %{"issues" => [...]}}

  """
  @spec get_issues() :: {:ok, map()} | {:error, any()}
  def get_issues do
    client()
    |> Tesla.get("/issues")
    |> parse_response()
  end

  @doc """
  Removes all issues reported so far.

  This is a Beta endpoint.

  ## Example

      iex> Qdrant.Api.Http.Service.clear_issues()
      {:ok, true}

  """
  @spec clear_issues() :: {:ok, boolean()} | {:error, any()}
  def clear_issues do
    client()
    |> Tesla.delete("/issues")
    |> parse_response()
  end

  # Private helpers
  defp parse_response({:ok, %Tesla.Env{status: 200, body: body}}) do
    {:ok, body}
  end

  defp parse_response({:error, reason}) do
    {:error, reason}
  end

  defp parse_response({:ok, %Tesla.Env{} = env}) do
    {:error, %{status: env.status, body: env.body}}
  end

  defp parse_response_text({:ok, %Tesla.Env{status: 200, body: body}}) when is_binary(body) do
    {:ok, body}
  end

  defp parse_response_text({:ok, %Tesla.Env{status: 200, body: body}}) do
    {:ok, to_string(body)}
  end

  defp parse_response_text({:error, reason}) do
    {:error, reason}
  end

  defp parse_response_text({:ok, %Tesla.Env{} = env}) do
    {:error, %{status: env.status, body: env.body}}
  end
end
