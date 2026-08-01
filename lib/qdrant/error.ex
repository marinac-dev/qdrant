defmodule Qdrant.Error do
  @moduledoc """
  Stable error returned by Qdrant client operations.

  Request credentials are never retained in this value.
  """

  defexception [
    :kind,
    :status,
    :body,
    :reason,
    :method,
    :url,
    :request_id,
    headers: []
  ]

  @type kind :: :configuration | :transport | :http | :decode | :response_too_large | :file

  @type t :: %__MODULE__{
          kind: kind(),
          status: non_neg_integer() | nil,
          body: term(),
          reason: term(),
          method: atom() | nil,
          url: String.t() | nil,
          request_id: String.t() | nil,
          headers: [{String.t(), String.t()}]
        }

  @impl true
  def message(%__MODULE__{kind: :configuration, reason: reason}), do: "invalid Qdrant configuration: #{reason}"

  def message(%__MODULE__{kind: :http, status: status, method: method, url: url}) do
    "Qdrant request #{format_method(method)}#{url || ""} returned HTTP #{status}"
  end

  def message(%__MODULE__{kind: kind, reason: reason, method: method, url: url}) do
    "Qdrant #{kind} error for #{format_method(method)}#{url || ""}: #{inspect(reason)}"
  end

  defp format_method(nil), do: ""
  defp format_method(method), do: String.upcase(to_string(method)) <> " "
end

defimpl Inspect, for: Qdrant.Error do
  import Inspect.Algebra

  def inspect(error, opts) do
    fields =
      error
      |> Map.from_struct()
      |> Map.update!(:headers, &redact_headers/1)
      |> Map.to_list()

    concat(["#Qdrant.Error<", to_doc(fields, opts), ">"])
  end

  defp redact_headers(headers) do
    Enum.map(headers, fn
      {name, value} ->
        if String.downcase(to_string(name)) in ["api-key", "authorization"] do
          {name, "[REDACTED]"}
        else
          {name, value}
        end
    end)
  end
end
